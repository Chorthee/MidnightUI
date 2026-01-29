-- Helper: Safe number
local function safe(val)
    if val == nil then return 0 end
    return val
end

-- Helper: Tag parsing for text overlays (safe for secret values)
local function ParseTags(str, unit)
    local curhp = UnitHealth(unit)
    local maxhp = UnitHealthMax(unit)
    local curpp = UnitPower(unit)
    local maxpp = UnitPowerMax(unit)
    local tags = {
        ["[curhp]"] = curhp or "",
        ["[maxhp]"] = maxhp or "",
        ["[curpp]"] = curpp or "",
        ["[maxpp]"] = maxpp or "",
        ["[name]"] = UnitName(unit) or "",
        ["[level]"] = UnitLevel(unit) or "",
        ["[class]"] = select(2, UnitClass(unit)) or "",
        -- [perhp] and math-based tags removed for safety
    }
    for tag, val in pairs(tags) do
        if val == nil then val = "" end
        str = str:gsub(tag, tostring(val))
    end
    return str
end

-- Hide Blizzard frames if custom frames are enabled
local function SetBlizzardFramesHidden(self)
    if self.db.profile.showPlayer and PlayerFrame then PlayerFrame:Hide() end
    if self.db.profile.showTarget and TargetFrame then TargetFrame:Hide() end
    if self.db.profile.showTargetTarget and TargetFrameToT then TargetFrameToT:Hide() end
end

-- Keep Blizzard PlayerFrame hidden if custom is enabled
local function HookBlizzardPlayerFrame(self)
    if PlayerFrame and not PlayerFrame._MidnightUIHooked then
        hooksecurefunc(PlayerFrame, "Show", function()
            if self.db and self.db.profile and self.db.profile.showPlayer then PlayerFrame:Hide() end
        end)
        PlayerFrame._MidnightUIHooked = true
    end
end

local defaults = {
    profile = {
        enabled = true,
        showPlayer = true,
        showTarget = true,
        showTargetTarget = true,
        spacing = 4,
        position = { point = "CENTER", x = 0, y = -200 },
        health = {
            width = 220, height = 24,
            color = {0.2, 0.8, 0.2, 1},
            bgColor = {0, 0, 0, 0.5},
            font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
            text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
            texture = "Flat"
        },
        power = {
            width = 220, height = 12,
            color = {0.2, 0.4, 0.8, 1},
            bgColor = {0, 0, 0, 0.5},
            font = "Friz Quadrata TT", fontSize = 12, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
            text = "[curpp] / [maxpp]", textPos = "CENTER",
            texture = "Flat"
        },

        info = {
            enabled = true, width = 220, height = 10,
            color = {0.8, 0.8, 0.2, 1},
            bgColor = {0, 0, 0, 0.5},
            font = "Friz Quadrata TT", fontSize = 10, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
            text = "[name] [level] [class]", textPos = "CENTER",
            texture = "Flat"
        }
    }

}

local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UnitFrames = MidnightUI:NewModule("UnitFrames", "AceEvent-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local frames = {}

local function CreateBar(parent, opts, yOffset)
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    bar:SetStatusBarTexture(LSM:Fetch("statusbar", opts.texture or "Flat"))
    bar:SetStatusBarColor(unpack(opts.color))
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetHeight(opts.height)
    bar:SetWidth(opts.width)
    bar:SetPoint("LEFT", 0, 0)
    bar:SetPoint("RIGHT", 0, 0)
    bar:SetPoint("TOP", 0, yOffset)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(unpack(opts.bgColor or {0,0,0,0.5}))
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont(LSM:Fetch("font", opts.font), opts.fontSize, opts.fontOutline)
    bar.text:SetTextColor(unpack(opts.fontColor or {1,1,1,1}))
    if opts.textPos == "LEFT" then
        bar.text:SetPoint("LEFT", 4, 0)
        bar.text:SetJustifyH("LEFT")
    elseif opts.textPos == "RIGHT" then
        bar.text:SetPoint("RIGHT", -4, 0)
        bar.text:SetJustifyH("RIGHT")
    else
        bar.text:SetPoint("CENTER")
        bar.text:SetJustifyH("CENTER")
    end
    return bar
end

-- Create the PlayerFrame

-- Generic frame creation for any unit
local function CreateUnitFrame(self, key, unit, anchor, anchorTo, anchorPoint, x, y)
    if frames[key] then return end
    local db = self.db.profile
    local spacing = db.spacing
    local h, p, i = db.health, db.power, db.info
    local totalHeight = h.height + p.height + (i.enabled and i.height or 0) + spacing * (i.enabled and 2 or 1)
    local width = math.max(h.width, p.width, i.width or 0)

    local frame = CreateFrame("Frame", "MidnightUI_"..key, UIParent, "BackdropTemplate")
    frame:SetSize(width, totalHeight)
    frame:SetPoint(anchorPoint or db.position.point, anchorTo or UIParent, anchorPoint or db.position.point, x or db.position.x, y or db.position.y)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:Show()
    MidnightUI:SkinFrame(frame)
    -- DEBUG: Add a red border to the custom frame
    frame.debugBorder = frame:CreateTexture(nil, "OVERLAY")
    frame.debugBorder:SetAllPoints()
    frame.debugBorder:SetColorTexture(1,0,0,0.5)
    frame.debugBorder:SetBlendMode("ADD")
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("[MidnightUI] Created frame: "..key.." at "..(x or db.position.x)..","..(y or db.position.y).." size "..width.."x"..totalHeight) end

    -- Health Bar
    local healthBar = CreateBar(frame, h, 0)
    healthBar:SetPoint("TOP", frame, "TOP", 0, 0)
    frame.healthBar = healthBar

    -- Power Bar
    local powerBar = CreateBar(frame, p, -(h.height + spacing))
    frame.powerBar = powerBar

    -- Info Bar (optional)
    if i.enabled then
        local infoBar = CreateBar(frame, i, -(h.height + p.height + spacing * 2))
        frame.infoBar = infoBar
    end

    frames[key] = frame
    self:UpdateUnitFrame(key, unit)
end

function UnitFrames:CreatePlayerFrame()
    if not self.db.profile.showPlayer then return end
    CreateUnitFrame(self, "PlayerFrame", "player")
end

function UnitFrames:CreateTargetFrame()
    if not self.db.profile.showTarget then return end
    -- Anchor to right of player frame if exists
    local anchorTo, x = frames.PlayerFrame, 320
    CreateUnitFrame(self, "TargetFrame", "target", anchorTo, "TOPLEFT", "TOPRIGHT", x, 0)
end

function UnitFrames:CreateTargetTargetFrame()
    if not self.db.profile.showTargetTarget then return end
    -- Anchor to below target frame if exists
    local anchorTo = frames.TargetFrame
    CreateUnitFrame(self, "TargetTargetFrame", "targettarget", anchorTo, "TOP", "BOTTOM", 0, -20)
end

-- Update all bars and text

function UnitFrames:UpdateUnitFrame(key, unit)
    local db = self.db.profile
    local frame = frames[key]
    if not frame then return end
    local h, p, i = db.health, db.power, db.info

    -- Health
    local curhp, maxhp = UnitHealth(unit), UnitHealthMax(unit)
    frame.healthBar:SetMinMaxValues(0, maxhp)
    frame.healthBar:SetValue(curhp)
    frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
    frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
    frame.healthBar.text:SetText(ParseTags(h.text, unit))

    -- Power
    local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
    frame.powerBar:SetMinMaxValues(0, maxpp)
    frame.powerBar:SetValue(curpp)
    frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
    frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
    frame.powerBar.text:SetText(ParseTags(p.text, unit))

    -- Info
    if frame.infoBar then
        frame.infoBar.text:SetFont(LSM:Fetch("font", i.font), i.fontSize, i.fontOutline)
        frame.infoBar.text:SetTextColor(unpack(i.fontColor or {1,1,1,1}))
        frame.infoBar.text:SetText(ParseTags(i.text, unit))
    end
end

-- Event-driven updates

function UnitFrames:PLAYER_ENTERING_WORLD()
    print("[MidnightUI] UnitFrames: PLAYER_ENTERING_WORLD fired")
    if not self.db or not self.db.profile then
        print("[MidnightUI] UnitFrames: DB not ready, skipping PLAYER_ENTERING_WORLD")
        return
    end
    HookBlizzardPlayerFrame(self)
    if self.db.profile.showPlayer then print("[MidnightUI] Creating PlayerFrame"); self:CreatePlayerFrame() end
    if self.db.profile.showTarget then print("[MidnightUI] Creating TargetFrame"); self:CreateTargetFrame() end
    if self.db.profile.showTargetTarget then print("[MidnightUI] Creating TargetTargetFrame"); self:CreateTargetTargetFrame() end
    SetBlizzardFramesHidden(self)
end


function UnitFrames:UNIT_HEALTH(event, unit)
    if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
    if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
    if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
    SetBlizzardFramesHidden(self)
end

function UnitFrames:UNIT_POWER_UPDATE(event, unit)
    if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
    if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
    if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
    SetBlizzardFramesHidden(self)
end

function UnitFrames:UNIT_DISPLAYPOWER(event, unit)
    if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
    if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
    if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
    SetBlizzardFramesHidden(self)
end

-- Integration with MidnightUI
function UnitFrames:OnInitialize()
    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function UnitFrames:OnDBReady()
    print("[MidnightUI] UnitFrames:OnDBReady called")
    if not MidnightUI.db.profile.modules.unitframes then print("[MidnightUI] UnitFrames module disabled in profile"); return end
    self.db = MidnightUI.db:RegisterNamespace("UnitFrames", defaults)
    print("[MidnightUI] UnitFrames: Registered namespace and events")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_POWER_UPDATE")
    self:RegisterEvent("UNIT_DISPLAYPOWER")
        -- Only now call PLAYER_ENTERING_WORLD logic
        self:PLAYER_ENTERING_WORLD()
end

function UnitFrames:GetOptions()
    local function colorOpt(name, desc, getter, setter, order)
        return {
            type = "color",
            name = name,
            desc = desc,
            hasAlpha = true,
            order = order,
            get = getter,
            set = setter,
        }
    end
    local function fontOpt(name, getter, setter, order)
        return {
            type = "select",
            dialogControl = "LSM30_Font",
            name = name,
            order = order,
            values = function() return LSM:HashTable("font") end,
            get = getter,
            set = setter,
        }
    end
    local function texOpt(name, getter, setter, order)
        return {
            type = "select",
            dialogControl = "LSM30_Statusbar",
            name = name,
            order = order,
            values = function() return LSM:HashTable("statusbar") end,
            get = getter,
            set = setter,
        }
    end
    return {
        type = "group",
        name = "Unit Frames",
        order = 20,
        args = {
            enabled = {
                name = "Enable Unit Frames",
                type = "toggle",
                order = 1,
                get = function() return self.db.profile.enabled end,
                set = function(_, v) self.db.profile.enabled = v; ReloadUI() end
            },
            showPlayer = {
                name = "Show Player Frame",
                type = "toggle",
                order = 2,
                get = function() return self.db.profile.showPlayer end,
                set = function(_, v) self.db.profile.showPlayer = v; ReloadUI() end
            },
            showTarget = {
                name = "Show Target Frame",
                type = "toggle",
                order = 3,
                get = function() return self.db.profile.showTarget end,
                set = function(_, v) self.db.profile.showTarget = v; ReloadUI() end
            },
            showTargetTarget = {
                name = "Show Target of Target Frame",
                type = "toggle",
                order = 4,
                get = function() return self.db.profile.showTargetTarget end,
                set = function(_, v) self.db.profile.showTargetTarget = v; ReloadUI() end
            },
            spacing = {
                name = "Bar Spacing",
                type = "range",
                min = 0, max = 20, step = 1,
                order = 5,
                get = function() return self.db.profile.spacing end,
                set = function(_, v) self.db.profile.spacing = v; self:UpdatePlayerFrame() end
            },
            position = {
                name = "Frame Position",
                type = "group",
                inline = true,
                order = 6,
                args = {
                    point = {
                        name = "Anchor Point",
                        type = "select",
                        order = 1,
                        values = {CENTER="CENTER",TOP="TOP",BOTTOM="BOTTOM",LEFT="LEFT",RIGHT="RIGHT",TOPLEFT="TOPLEFT",TOPRIGHT="TOPRIGHT",BOTTOMLEFT="BOTTOMLEFT",BOTTOMRIGHT="BOTTOMRIGHT"},
                        get = function() return self.db.profile.position.point end,
                        set = function(_, v) self.db.profile.position.point = v; self:UpdatePlayerFrame() end
                    },
                    x = {
                        name = "X Offset",
                        type = "range",
                        min = -1000, max = 1000, step = 1,
                        order = 2,
                        get = function() return self.db.profile.position.x end,
                        set = function(_, v) self.db.profile.position.x = v; self:UpdatePlayerFrame() end
                    },
                    y = {
                        name = "Y Offset",
                        type = "range",
                        min = -1000, max = 1000, step = 1,
                        order = 3,
                        get = function() return self.db.profile.position.y end,
                        set = function(_, v) self.db.profile.position.y = v; self:UpdatePlayerFrame() end
                    },
                },
            },
            health = {
                name = "Health Bar",
                type = "group",
                order = 10,
                args = {
                    width = { type = "range", name = "Width", min = 50, max = 600, step = 1, order = 1,
                        get = function() return self.db.profile.health.width end,
                        set = function(_, v) self.db.profile.health.width = v; self:UpdatePlayerFrame() end },
                    height = { type = "range", name = "Height", min = 8, max = 60, step = 1, order = 2,
                        get = function() return self.db.profile.health.height end,
                        set = function(_, v) self.db.profile.health.height = v; self:UpdatePlayerFrame() end },
                    color = colorOpt("Bar Color", nil,
                        function() return unpack(self.db.profile.health.color) end,
                        function(_,r,g,b,a) self.db.profile.health.color = {r,g,b,a}; self:UpdatePlayerFrame() end, 3),
                    bgColor = colorOpt("Background Color", nil,
                        function() return unpack(self.db.profile.health.bgColor) end,
                        function(_,r,g,b,a) self.db.profile.health.bgColor = {r,g,b,a}; self:UpdatePlayerFrame() end, 4),
                    font = fontOpt("Font",
                        function() return self.db.profile.health.font end,
                        function(_,v) self.db.profile.health.font = v; self:UpdatePlayerFrame() end, 5),
                    fontSize = { type = "range", name = "Font Size", min = 8, max = 32, step = 1, order = 6,
                        get = function() return self.db.profile.health.fontSize end,
                        set = function(_,v) self.db.profile.health.fontSize = v; self:UpdatePlayerFrame() end },
                    fontOutline = { type = "select", name = "Font Outline", order = 7,
                        values = {NONE="NONE",OUTLINE="OUTLINE",THICKOUTLINE="THICKOUTLINE"},
                        get = function() return self.db.profile.health.fontOutline end,
                        set = function(_,v) self.db.profile.health.fontOutline = v; self:UpdatePlayerFrame() end },
                    fontColor = colorOpt("Font Color", nil,
                        function() return unpack(self.db.profile.health.fontColor) end,
                        function(_,r,g,b,a) self.db.profile.health.fontColor = {r,g,b,a}; self:UpdatePlayerFrame() end, 8),
                    text = { type = "input", name = "Text Format", order = 9,
                        get = function() return self.db.profile.health.text end,
                        set = function(_,v) self.db.profile.health.text = v; self:UpdatePlayerFrame() end },
                    textPos = { type = "select", name = "Text Position", order = 10,
                        values = {LEFT="LEFT",CENTER="CENTER",RIGHT="RIGHT"},
                        get = function() return self.db.profile.health.textPos end,
                        set = function(_,v) self.db.profile.health.textPos = v; self:UpdatePlayerFrame() end },
                    texture = texOpt("Bar Texture",
                        function() return self.db.profile.health.texture end,
                        function(_,v) self.db.profile.health.texture = v; self:UpdatePlayerFrame() end, 11),
                }
            },
            power = {
                name = "Power Bar",
                type = "group",
                order = 11,
                args = {
                    width = { type = "range", name = "Width", min = 50, max = 600, step = 1, order = 1,
                        get = function() return self.db.profile.power.width end,
                        set = function(_, v) self.db.profile.power.width = v; self:UpdatePlayerFrame() end },
                    height = { type = "range", name = "Height", min = 8, max = 60, step = 1, order = 2,
                        get = function() return self.db.profile.power.height end,
                        set = function(_, v) self.db.profile.power.height = v; self:UpdatePlayerFrame() end },
                    color = colorOpt("Bar Color", nil,
                        function() return unpack(self.db.profile.power.color) end,
                        function(_,r,g,b,a) self.db.profile.power.color = {r,g,b,a}; self:UpdatePlayerFrame() end, 3),
                    bgColor = colorOpt("Background Color", nil,
                        function() return unpack(self.db.profile.power.bgColor) end,
                        function(_,r,g,b,a) self.db.profile.power.bgColor = {r,g,b,a}; self:UpdatePlayerFrame() end, 4),
                    font = fontOpt("Font",
                        function() return self.db.profile.power.font end,
                        function(_,v) self.db.profile.power.font = v; self:UpdatePlayerFrame() end, 5),
                    fontSize = { type = "range", name = "Font Size", min = 8, max = 32, step = 1, order = 6,
                        get = function() return self.db.profile.power.fontSize end,
                        set = function(_,v) self.db.profile.power.fontSize = v; self:UpdatePlayerFrame() end },
                    fontOutline = { type = "select", name = "Font Outline", order = 7,
                        values = {NONE="NONE",OUTLINE="OUTLINE",THICKOUTLINE="THICKOUTLINE"},
                        get = function() return self.db.profile.power.fontOutline end,
                        set = function(_,v) self.db.profile.power.fontOutline = v; self:UpdatePlayerFrame() end },
                    fontColor = colorOpt("Font Color", nil,
                        function() return unpack(self.db.profile.power.fontColor) end,
                        function(_,r,g,b,a) self.db.profile.power.fontColor = {r,g,b,a}; self:UpdatePlayerFrame() end, 8),
                    text = { type = "input", name = "Text Format", order = 9,
                        get = function() return self.db.profile.power.text end,
                        set = function(_,v) self.db.profile.power.text = v; self:UpdatePlayerFrame() end },
                    textPos = { type = "select", name = "Text Position", order = 10,
                        values = {LEFT="LEFT",CENTER="CENTER",RIGHT="RIGHT"},
                        get = function() return self.db.profile.power.textPos end,
                        set = function(_,v) self.db.profile.power.textPos = v; self:UpdatePlayerFrame() end },
                    texture = texOpt("Bar Texture",
                        function() return self.db.profile.power.texture end,
                        function(_,v) self.db.profile.power.texture = v; self:UpdatePlayerFrame() end, 11),
                }
            },
            info = {
                name = "Info Bar",
                type = "group",
                order = 12,
                args = {
                    enabled = { type = "toggle", name = "Show Info Bar", order = 0,
                        get = function() return self.db.profile.info.enabled end,
                        set = function(_,v) self.db.profile.info.enabled = v; self:UpdatePlayerFrame() end },
                    width = { type = "range", name = "Width", min = 50, max = 600, step = 1, order = 1,
                        get = function() return self.db.profile.info.width end,
                        set = function(_, v) self.db.profile.info.width = v; self:UpdatePlayerFrame() end },
                    height = { type = "range", name = "Height", min = 8, max = 60, step = 1, order = 2,
                        get = function() return self.db.profile.info.height end,
                        set = function(_, v) self.db.profile.info.height = v; self:UpdatePlayerFrame() end },
                    color = colorOpt("Bar Color", nil,
                        function() return unpack(self.db.profile.info.color) end,
                        function(_,r,g,b,a) self.db.profile.info.color = {r,g,b,a}; self:UpdatePlayerFrame() end, 3),
                    bgColor = colorOpt("Background Color", nil,
                        function() return unpack(self.db.profile.info.bgColor) end,
                        function(_,r,g,b,a) self.db.profile.info.bgColor = {r,g,b,a}; self:UpdatePlayerFrame() end, 4),
                    font = fontOpt("Font",
                        function() return self.db.profile.info.font end,
                        function(_,v) self.db.profile.info.font = v; self:UpdatePlayerFrame() end, 5),
                    fontSize = { type = "range", name = "Font Size", min = 8, max = 32, step = 1, order = 6,
                        get = function() return self.db.profile.info.fontSize end,
                        set = function(_,v) self.db.profile.info.fontSize = v; self:UpdatePlayerFrame() end },
                    fontOutline = { type = "select", name = "Font Outline", order = 7,
                        values = {NONE="NONE",OUTLINE="OUTLINE",THICKOUTLINE="THICKOUTLINE"},
                        get = function() return self.db.profile.info.fontOutline end,
                        set = function(_,v) self.db.profile.info.fontOutline = v; self:UpdatePlayerFrame() end },
                    fontColor = colorOpt("Font Color", nil,
                        function() return unpack(self.db.profile.info.fontColor) end,
                        function(_,r,g,b,a) self.db.profile.info.fontColor = {r,g,b,a}; self:UpdatePlayerFrame() end, 8),
                    text = { type = "input", name = "Text Format", order = 9,
                        get = function() return self.db.profile.info.text end,
                        set = function(_,v) self.db.profile.info.text = v; self:UpdatePlayerFrame() end },
                    textPos = { type = "select", name = "Text Position", order = 10,
                        values = {LEFT="LEFT",CENTER="CENTER",RIGHT="RIGHT"},
                        get = function() return self.db.profile.info.textPos end,
                        set = function(_,v) self.db.profile.info.textPos = v; self:UpdatePlayerFrame() end },
                    texture = texOpt("Bar Texture",
                        function() return self.db.profile.info.texture end,
                        function(_,v) self.db.profile.info.texture = v; self:UpdatePlayerFrame() end, 11),
                }
            },
            -- ...add any other options here...
        },
    }
end

return UnitFrames