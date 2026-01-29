-- Helper: Safe number
-- Remove tag parsing helpers; use direct formatting functions instead


-- Helper: Tag parsing for text overlays (safe for secret values)
local function ParseTags(str, unit)
    local curhp = UnitHealth(unit)
    local maxhp = UnitHealthMax(unit)
    local curpp = UnitPower(unit)
    local maxpp = UnitPowerMax(unit)
    -- Only use the always-safe gsub loop, no pre-replacement
    return (str:gsub("%[(.-)%]", function(tag)
        -- Built-in tags
        if tag == "curhp" then return safe(curhp) end
        if tag == "maxhp" then return safe(maxhp) end
        if tag == "curpp" then return safe(curpp) end
        if tag == "maxpp" then return safe(maxpp) end
        if tag == "name" then return safe(UnitName(unit)) end
        if tag == "level" then return safe(UnitLevel(unit)) end
        if tag == "class" then local _, class = UnitClass(unit); return safe(class) end
        -- Custom tag functions
        local ok, value = pcall(function()
            if tagFuncs[tag] then
                return tagFuncs[tag](unit)
            end
            return nil
        end)
        if not ok then return "" end
        return safe(value)
    end))
end

-- Hide Blizzard frames if custom frames are enabled
local function SetBlizzardFramesHidden(self)
    if self.db.profile.showPlayer and PlayerFrame then PlayerFrame:Hide(); PlayerFrame:UnregisterAllEvents(); PlayerFrame:Hide() end
    if self.db.profile.showTarget and TargetFrame then TargetFrame:Hide(); TargetFrame:UnregisterAllEvents(); TargetFrame:Hide() end
    if self.db.profile.showTargetTarget and TargetFrameToT then TargetFrameToT:Hide(); TargetFrameToT:UnregisterAllEvents(); TargetFrameToT:Hide() end
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
        position = { point = "CENTER", x = 0, y = -200 }, -- Player
        targetPosition = { point = "TOPLEFT", x = 320, y = 0 }, -- Target
        totPosition = { point = "TOP", x = 0, y = -20 }, -- Target of Target
        health = {
            enabled = true, -- NEW
            width = 220, height = 24,
            color = {0.2, 0.8, 0.2, 1},
            bgColor = {0, 0, 0, 0.5},
            font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
            text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
            texture = "Flat"
        },
        power = {
            enabled = true, -- NEW
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
    local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
    local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

    -- Use SecureUnitButtonTemplate for all unit frames
    local frameType = "Button"
    local template = "SecureUnitButtonTemplate,BackdropTemplate"
    local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
    frame:SetSize(width, totalHeight)
    -- Ensure anchorTo is always a frame, never a string
    local myPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
    local relTo = (type(anchorTo) == "table" and anchorTo) or UIParent
    local relPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
    local px = x or (db.position and db.position.x) or 0
    local py = y or (db.position and db.position.y) or 0
    frame:SetPoint(myPoint, relTo, relPoint, px, py)
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

    local yOffset = 0
    if h.enabled then
        local healthBar = CreateBar(frame, h, yOffset)
        healthBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
        frame.healthBar = healthBar
        yOffset = yOffset - h.height - spacing
    end
    if p.enabled then
        local powerBar = CreateBar(frame, p, yOffset)
        frame.powerBar = powerBar
        yOffset = yOffset - p.height - spacing
    end
    if i.enabled then
        local infoBar = CreateBar(frame, i, yOffset)
        frame.infoBar = infoBar
    end

    -- Make all frames secure unit buttons for click targeting
    if key == "PlayerFrame" then
        frame:SetAttribute("unit", "player")
        frame:SetAttribute("type", "target")
        frame:RegisterForClicks("AnyUp")
    elseif key == "TargetFrame" then
        frame:SetAttribute("unit", "target")
        frame:SetAttribute("type", "target")
        frame:RegisterForClicks("AnyUp")
    elseif key == "TargetTargetFrame" then
        frame:SetAttribute("unit", "targettarget")
        frame:SetAttribute("type", "target")
        frame:RegisterForClicks("AnyUp")
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
    local db = self.db.profile
    local anchorTo = UIParent
    local pos = db.targetPosition or { point = "TOPLEFT", x = 320, y = 0 }
    CreateUnitFrame(self, "TargetFrame", "target", anchorTo, pos.point, pos.point, pos.x, pos.y)
end

function UnitFrames:CreateTargetTargetFrame()
    if not self.db.profile.showTargetTarget then return end
    local db = self.db.profile
    local anchorTo = UIParent
    local pos = db.totPosition or { point = "TOP", x = 0, y = -20 }
    CreateUnitFrame(self, "TargetTargetFrame", "targettarget", anchorTo, pos.point, pos.point, pos.x, pos.y)
end

-- Update all bars and text

function UnitFrames:UpdateUnitFrame(key, unit)
    local db = self.db.profile
    local frame = frames[key]
    if not frame then return end
    local h, p, i = db.health, db.power, db.info

    -- Special logic for TargetFrame: only show if target exists
    if key == "TargetFrame" then
        if not UnitExists("target") then
            frame:Hide()
            return
        else
            frame:Show()
        end
    end
    -- Special logic for Target of Target: only show if targettarget exists
    if key == "TargetTargetFrame" then
        if not UnitExists("targettarget") then
            frame:Hide()
            return
        else
            frame:Show()
        end
    end

    -- Health
    local curhp, maxhp = UnitHealth(unit), UnitHealthMax(unit)
    frame.healthBar:SetMinMaxValues(0, maxhp)
    frame.healthBar:SetValue(curhp)
    frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
    frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
    local hpPct = nil
    pcall(function() hpPct = (maxhp and maxhp > 0) and math.floor((curhp / maxhp) * 100) or 0 end)
    local healthStr = string.format("%s / %s (%s%%)", tostring(curhp or 0), tostring(maxhp or 0), tostring(hpPct or 0))
    frame.healthBar.text:SetText(healthStr)

    -- Power
    local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
    frame.powerBar:SetMinMaxValues(0, maxpp)
    frame.powerBar:SetValue(curpp)
    frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
    frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
    local powerStr = string.format("%s / %s", tostring(curpp or 0), tostring(maxpp or 0))
    frame.powerBar.text:SetText(powerStr)

    -- Info
    if frame.infoBar then
        frame.infoBar.text:SetFont(LSM:Fetch("font", i.font), i.fontSize, i.fontOutline)
        frame.infoBar.text:SetTextColor(unpack(i.fontColor or {1,1,1,1}))
        local name = UnitName(unit) or ""
        local level = UnitLevel(unit) or ""
        local _, class = UnitClass(unit)
        class = class or ""
        local infoStr = string.format("%s %s %s", name, level, class)
        frame.infoBar.text:SetText(infoStr)
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


function UnitFrames:PLAYER_TARGET_CHANGED()
    if self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
    if self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
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

function UnitFrames:UNIT_TARGET(event, unit)
    if unit == "target" and self.db.profile.showTargetTarget then
        self:UpdateUnitFrame("TargetTargetFrame", "targettarget")
    end
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
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_TARGET")
    -- Only now call PLAYER_ENTERING_WORLD logic
    self:PLAYER_ENTERING_WORLD()
end

function UnitFrames:GetOptions()
    local playerPosition = {
    name = "Player Frame Position",
    type = "group",
    inline = true,
    order = 2,
    args = {
        point = {
            name = "Anchor Point",
            type = "select",
            order = 1,
            values = {CENTER="CENTER",TOP="TOP",BOTTOM="BOTTOM",LEFT="LEFT",RIGHT="RIGHT",TOPLEFT="TOPLEFT",TOPRIGHT="TOPRIGHT",BOTTOMLEFT="BOTTOMLEFT",BOTTOMRIGHT="BOTTOMRIGHT"},
            get = function() return self.db.profile.position.point end,
            set = function(_, v) self.db.profile.position.point = v; if self.UpdateUnitFrame then self:UpdateUnitFrame('PlayerFrame', 'player') end end
        },
        x = {
            name = "X Offset",
            type = "range",
            min = -1000, max = 1000, step = 1,
            order = 2,
            get = function() return self.db.profile.position.x end,
            set = function(_, v)
                function UnitFrames:GetOptions()
                    -- Tab group for Player, Target, and Target of Target
                    local options = {
                        type = "group",
                        name = "Unit Frames",
                        args = {
                            frames = {
                                type = "tab",
                                name = "Frames",
                                order = 1,
                                args = {
                                    player = {
                                        type = "group",
                                        name = "Player",
                                        order = 1,
                                        args = {
                                            position = {
                                                name = "Player Frame Position",
                                                type = "group",
                                                inline = true,
                                                order = 1,
                                                args = {
                                                    point = {
                                                        name = "Anchor Point",
                                                        type = "select",
                                                        order = 1,
                                                        values = {CENTER="CENTER",TOP="TOP",BOTTOM="BOTTOM",LEFT="LEFT",RIGHT="RIGHT",TOPLEFT="TOPLEFT",TOPRIGHT="TOPRIGHT",BOTTOMLEFT="BOTTOMLEFT",BOTTOMRIGHT="BOTTOMRIGHT"},
                                                        get = function() return self.db.profile.position.point end,
                                                        set = function(_, v) self.db.profile.position.point = v; if self.UpdateUnitFrame then self:UpdateUnitFrame('PlayerFrame', 'player') end end
                                                    },
                                                    x = {
                                                        name = "X Offset",
                                                        type = "range",
                                                        min = -1000, max = 1000, step = 1,
                                                        order = 2,
                                                        get = function() return self.db.profile.position.x end,
                                                        set = function(_, v)
                                                            self.db.profile.position.x = v;
                                                            local frame = frames and frames.PlayerFrame
                                                            if frame then
                                                                local db = self.db.profile
                                                                local myPoint = db.position and db.position.point or "CENTER"
                                                                local px = db.position and db.position.x or 0
                                                                local py = db.position and db.position.y or 0
                                                                frame:ClearAllPoints()
                                                                frame:SetPoint(myPoint, UIParent, myPoint, px, py)
                                                            end
                                                            if self.UpdateUnitFrame then self:UpdateUnitFrame('PlayerFrame', 'player') end
                                                        end
                                                    },
                                                    y = {
                                                        name = "Y Offset",
                                                        type = "range",
                                                        min = -1000, max = 1000, step = 1,
                                                        order = 3,
                                                        get = function() return self.db.profile.position.y end,
                                                        set = function(_, v)
                                                            self.db.profile.position.y = v;
                                                            local frame = frames and frames.PlayerFrame
                                                            if frame then
                                                                local db = self.db.profile
                                                                local myPoint = db.position and db.position.point or "CENTER"
                                                                local px = db.position and db.position.x or 0
                                                                local py = db.position and db.position.y or 0
                                                                frame:ClearAllPoints()
                                                                frame:SetPoint(myPoint, UIParent, myPoint, px, py)
                                                            end
                                                            if self.UpdateUnitFrame then self:UpdateUnitFrame('PlayerFrame', 'player') end
                                                        end
                                                    },
                                                },
                                            },
                                        },
                                    },
                                    target = {
                                        type = "group",
                                        name = "Target",
                                        order = 2,
                                        args = {
                                            position = {
                                                name = "Target Frame Position",
                                                type = "group",
                                                inline = true,
                                                order = 1,
                                                args = {
                                                    point = {
                                                        name = "Anchor Point",
                                                        type = "select",
                                                        order = 1,
                                                        values = {CENTER="CENTER",TOP="TOP",BOTTOM="BOTTOM",LEFT="LEFT",RIGHT="RIGHT",TOPLEFT="TOPLEFT",TOPRIGHT="TOPRIGHT",BOTTOMLEFT="BOTTOMLEFT",BOTTOMRIGHT="BOTTOMRIGHT"},
                                                        get = function() return self.db.profile.targetPosition.point end,
                                                        set = function(_, v)
                                                            self.db.profile.targetPosition.point = v;
                                                            local frame = frames and frames.TargetFrame
                                                            if frame then
                                                                local db = self.db.profile
                                                                local myPoint = db.targetPosition and db.targetPosition.point or "TOPLEFT"
                                                                local px = db.targetPosition and db.targetPosition.x or 320
                                                                local py = db.targetPosition and db.targetPosition.y or 0
                                                                frame:ClearAllPoints()
                                                                frame:SetPoint(myPoint, UIParent, myPoint, px, py)
                                                            end
                                                            if self.UpdateUnitFrame then self:UpdateUnitFrame('TargetFrame', 'target') end
                                                        end
                                                    },
                                                    x = {
                                                        name = "X Offset",
                                                        type = "range",
                                                        min = -2000, max = 2000, step = 1,
                                                        order = 2,
                                                        get = function() return self.db.profile.targetPosition.x end,
                                                        set = function(_, v)
                                                            self.db.profile.targetPosition.x = v;
                                                            local frame = frames and frames.TargetFrame
                                                            if frame then
                                                                local db = self.db.profile
                                                                local myPoint = db.targetPosition and db.targetPosition.point or "TOPLEFT"
                                                                local px = db.targetPosition and db.targetPosition.x or 320
                                                                local py = db.targetPosition and db.targetPosition.y or 0
                                                                frame:ClearAllPoints()
                                                                frame:SetPoint(myPoint, UIParent, myPoint, px, py)
                                                            end
                                                            if self.UpdateUnitFrame then self:UpdateUnitFrame('TargetFrame', 'target') end
                                                        end
                                                    },
                                                    y = {
                                                        name = "Y Offset",
                                                        type = "range",
                                                        min = -2000, max = 2000, step = 1,
                                                        order = 3,
                                                        get = function() return self.db.profile.targetPosition.y end,
                                                        set = function(_, v)
                                                            self.db.profile.targetPosition.y = v;
                                                            local frame = frames and frames.TargetFrame
                                                            if frame then
                                                                local db = self.db.profile
                                                                local myPoint = db.targetPosition and db.targetPosition.point or "TOPLEFT"
                                                                local px = db.targetPosition and db.targetPosition.x or 320
                                                                local py = db.targetPosition and db.targetPosition.y or 0
                                                                frame:ClearAllPoints()
                                                                frame:SetPoint(myPoint, UIParent, myPoint, px, py)
                                                            end
                                                            if self.UpdateUnitFrame then self:UpdateUnitFrame('TargetFrame', 'target') end
                                                        end
                                                    },
                                                },
                                            },
                                        },
                                    },
                                    tot = {
                                        type = "group",
                                        name = "Target of Target",
                                        order = 3,
                                        args = {
                                            position = {
                                                name = "Target of Target Frame Position",
                                                type = "group",
                                                inline = true,
                                                order = 1,
                                                args = {
                                                    point = {
                                                        name = "Anchor Point",
                                                        type = "select",
                                                        order = 1,
                                                        values = {CENTER="CENTER",TOP="TOP",BOTTOM="BOTTOM",LEFT="LEFT",RIGHT="RIGHT",TOPLEFT="TOPLEFT",TOPRIGHT="TOPRIGHT",BOTTOMLEFT="BOTTOMLEFT",BOTTOMRIGHT="BOTTOMRIGHT"},
                                                        get = function() return self.db.profile.totPosition.point end,
                                                        set = function(_, v)
                                                            self.db.profile.totPosition.point = v;
                                                            local frame = frames and frames.TargetTargetFrame
                                                            if frame then
                                                                local db = self.db.profile
                                                                local myPoint = db.totPosition and db.totPosition.point or "TOP"
                                                                local px = db.totPosition and db.totPosition.x or 0
                                                                local py = db.totPosition and db.totPosition.y or -20
                                                                frame:ClearAllPoints()
                                                                frame:SetPoint(myPoint, UIParent, myPoint, px, py)
                                                            end
                                                            if self.UpdateUnitFrame then self:UpdateUnitFrame('TargetTargetFrame', 'targettarget') end
                                                        end
                                                    },
                                                    x = {
                                                        name = "X Offset",
                                                        type = "range",
                                                        min = -2000, max = 2000, step = 1,
                                                        order = 2,
                                                        get = function() return self.db.profile.totPosition.x end,
                                                        set = function(_, v)
                                                            self.db.profile.totPosition.x = v;
                                                            local frame = frames and frames.TargetTargetFrame
                                                            if frame then
                                                                local db = self.db.profile
                                                                local myPoint = db.totPosition and db.totPosition.point or "TOP"
                                                                local px = db.totPosition and db.totPosition.x or 0
                                                                local py = db.totPosition and db.totPosition.y or -20
                                                                frame:ClearAllPoints()
                                                                frame:SetPoint(myPoint, UIParent, myPoint, px, py)
                                                            end
                                                            if self.UpdateUnitFrame then self:UpdateUnitFrame('TargetTargetFrame', 'targettarget') end
                                                        end
                                                    },
                                                    y = {
                                                        name = "Y Offset",
                                                        type = "range",
                                                        min = -2000, max = 2000, step = 1,
                                                        order = 3,
                                                        get = function() return self.db.profile.totPosition.y end,
                                                        set = function(_, v)
                                                            self.db.profile.totPosition.y = v;
                                                            local frame = frames and frames.TargetTargetFrame
                                                            if frame then
                                                                local db = self.db.profile
                                                                local myPoint = db.totPosition and db.totPosition.point or "TOP"
                                                                local px = db.totPosition and db.totPosition.x or 0
                                                                local py = db.totPosition and db.totPosition.y or -20
                                                                frame:ClearAllPoints()
                                                                frame:SetPoint(myPoint, UIParent, myPoint, px, py)
                                                            end
                                                            if self.UpdateUnitFrame then self:UpdateUnitFrame('TargetTargetFrame', 'targettarget') end
                                                        end
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    }
                    return options
            frame:SetAttribute("unit", "player")
            frame:SetAttribute("type", "target")
            frame:RegisterForClicks("AnyUp")
        elseif key == "TargetFrame" then
            frame:SetAttribute("unit", "target")
            frame:SetAttribute("type", "target")
            frame:RegisterForClicks("AnyUp")
        elseif key == "TargetTargetFrame" then
            frame:SetAttribute("unit", "targettarget")
            frame:SetAttribute("type", "target")
            frame:RegisterForClicks("AnyUp")
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
        local db = self.db.profile
        local anchorTo = UIParent
        local pos = db.targetPosition or { point = "TOPLEFT", x = 320, y = 0 }
        CreateUnitFrame(self, "TargetFrame", "target", anchorTo, pos.point, pos.point, pos.x, pos.y)
    end

    function UnitFrames:CreateTargetTargetFrame()
        if not self.db.profile.showTargetTarget then return end
        local db = self.db.profile
        local anchorTo = UIParent
        local pos = db.totPosition or { point = "TOP", x = 0, y = -20 }
        CreateUnitFrame(self, "TargetTargetFrame", "targettarget", anchorTo, pos.point, pos.point, pos.x, pos.y)
    end

    -- Update all bars and text

    function UnitFrames:UpdateUnitFrame(key, unit)
        local db = self.db.profile
        local frame = frames[key]
        if not frame then return end
        local h, p, i = db.health, db.power, db.info

        -- Special logic for TargetFrame: only show if target exists
        if key == "TargetFrame" then
            if not UnitExists("target") then
                frame:Hide()
                return
            else
                frame:Show()
            end
        end
        -- Special logic for Target of Target: only show if targettarget exists
        if key == "TargetTargetFrame" then
            if not UnitExists("targettarget") then
                frame:Hide()
                return
            else
                frame:Show()
            end
        end

        -- Health
        local curhp, maxhp = UnitHealth(unit), UnitHealthMax(unit)
        frame.healthBar:SetMinMaxValues(0, maxhp)
        frame.healthBar:SetValue(curhp)
        frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
        frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
        local hpPct = nil
        pcall(function() hpPct = (maxhp and maxhp > 0) and math.floor((curhp / maxhp) * 100) or 0 end)
        local healthStr = string.format("%s / %s (%s%%)", tostring(curhp or 0), tostring(maxhp or 0), tostring(hpPct or 0))
        frame.healthBar.text:SetText(healthStr)

        -- Power
        local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
        frame.powerBar:SetMinMaxValues(0, maxpp)
        frame.powerBar:SetValue(curpp)
        frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
        frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
        local powerStr = string.format("%s / %s", tostring(curpp or 0), tostring(maxpp or 0))
        frame.powerBar.text:SetText(powerStr)

        -- Info
        if frame.infoBar then
            frame.infoBar.text:SetFont(LSM:Fetch("font", i.font), i.fontSize, i.fontOutline)
            frame.infoBar.text:SetTextColor(unpack(i.fontColor or {1,1,1,1}))
            local name = UnitName(unit) or ""
            local level = UnitLevel(unit) or ""
            local _, class = UnitClass(unit)
            class = class or ""
            local infoStr = string.format("%s %s %s", name, level, class)
            frame.infoBar.text:SetText(infoStr)
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


    function UnitFrames:PLAYER_TARGET_CHANGED()
        if self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
        if self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
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

    function UnitFrames:UNIT_TARGET(event, unit)
        if unit == "target" and self.db.profile.showTargetTarget then
            self:UpdateUnitFrame("TargetTargetFrame", "targettarget")
        end
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
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterEvent("UNIT_TARGET")
        -- Only now call PLAYER_ENTERING_WORLD logic
        self:PLAYER_ENTERING_WORLD()
    end

    function UnitFrames:GetOptions()
        -- Helper: Safe number
        -- Remove tag parsing helpers; use direct formatting functions instead

        -- Helper: Tag parsing for text overlays (safe for secret values)
        local function ParseTags(str, unit)
            local curhp = UnitHealth(unit)
            local maxhp = UnitHealthMax(unit)
            local curpp = UnitPower(unit)
            local maxpp = UnitPowerMax(unit)
            -- Only use the always-safe gsub loop, no pre-replacement
            return (str:gsub("%[(.-)%]", function(tag)
                -- Built-in tags
                if tag == "curhp" then return safe(curhp) end
                if tag == "maxhp" then return safe(maxhp) end
                if tag == "curpp" then return safe(curpp) end
                if tag == "maxpp" then return safe(maxpp) end
                if tag == "name" then return safe(UnitName(unit)) end
                if tag == "level" then return safe(UnitLevel(unit)) end
                if tag == "class" then local _, class = UnitClass(unit); return safe(class) end
                -- Custom tag functions
                local ok, value = pcall(function()
                    if tagFuncs[tag] then
                        return tagFuncs[tag](unit)
                    end
                    return nil
                end)
                if not ok then return "" end
                return safe(value)
            end))
        end

        -- Hide Blizzard frames if custom frames are enabled
        local function SetBlizzardFramesHidden(self)
            if self.db.profile.showPlayer and PlayerFrame then PlayerFrame:Hide(); PlayerFrame:UnregisterAllEvents(); PlayerFrame:Hide() end
            if self.db.profile.showTarget and TargetFrame then TargetFrame:Hide(); TargetFrame:UnregisterAllEvents(); TargetFrame:Hide() end
            if self.db.profile.showTargetTarget and TargetFrameToT then TargetFrameToT:Hide(); TargetFrameToT:UnregisterAllEvents(); TargetFrameToT:Hide() end
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
                position = { point = "CENTER", x = 0, y = -200 }, -- Player
                targetPosition = { point = "TOPLEFT", x = 320, y = 0 }, -- Target
                totPosition = { point = "TOP", x = 0, y = -20 }, -- Target of Target
                health = {
                    enabled = true, -- NEW
                    width = 220, height = 24,
                    color = {0.2, 0.8, 0.2, 1},
                    bgColor = {0, 0, 0, 0.5},
                    font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                    texture = "Flat"
                },
                power = {
                    enabled = true, -- NEW
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
            local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
            local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

            -- Use SecureUnitButtonTemplate for all unit frames
            local frameType = "Button"
            local template = "SecureUnitButtonTemplate,BackdropTemplate"
            local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
            frame:SetSize(width, totalHeight)
            -- Ensure anchorTo is always a frame, never a string
            local myPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
            local relTo = (type(anchorTo) == "table" and anchorTo) or UIParent
            local relPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
            local px = x or (db.position and db.position.x) or 0
            local py = y or (db.position and db.position.y) or 0
            frame:SetPoint(myPoint, relTo, relPoint, px, py)
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

            local yOffset = 0
            if h.enabled then
                local healthBar = CreateBar(frame, h, yOffset)
                healthBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
                frame.healthBar = healthBar
                yOffset = yOffset - h.height - spacing
            end
            if p.enabled then
                local powerBar = CreateBar(frame, p, yOffset)
                frame.powerBar = powerBar
                yOffset = yOffset - p.height - spacing
            end
            if i.enabled then
                local infoBar = CreateBar(frame, i, yOffset)
                frame.infoBar = infoBar
            end

            -- Make all frames secure unit buttons for click targeting
            if key == "PlayerFrame" then
                frame:SetAttribute("unit", "player")
                frame:SetAttribute("type", "target")
                frame:RegisterForClicks("AnyUp")
            elseif key == "TargetFrame" then
                frame:SetAttribute("unit", "target")
                frame:SetAttribute("type", "target")
                frame:RegisterForClicks("AnyUp")
            elseif key == "TargetTargetFrame" then
                frame:SetAttribute("unit", "targettarget")
                frame:SetAttribute("type", "target")
                frame:RegisterForClicks("AnyUp")
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
            local db = self.db.profile
            local anchorTo = UIParent
            local pos = db.targetPosition or { point = "TOPLEFT", x = 320, y = 0 }
            CreateUnitFrame(self, "TargetFrame", "target", anchorTo, pos.point, pos.point, pos.x, pos.y)
        end

        function UnitFrames:CreateTargetTargetFrame()
            if not self.db.profile.showTargetTarget then return end
            local db = self.db.profile
            local anchorTo = UIParent
            local pos = db.totPosition or { point = "TOP", x = 0, y = -20 }
            CreateUnitFrame(self, "TargetTargetFrame", "targettarget", anchorTo, pos.point, pos.point, pos.x, pos.y)
        end

        -- Update all bars and text

        function UnitFrames:UpdateUnitFrame(key, unit)
            local db = self.db.profile
            local frame = frames[key]
            if not frame then return end
            local h, p, i = db.health, db.power, db.info

            -- Special logic for TargetFrame: only show if target exists
            if key == "TargetFrame" then
                if not UnitExists("target") then
                    frame:Hide()
                    return
                else
                    frame:Show()
                end
            end
            -- Special logic for Target of Target: only show if targettarget exists
            if key == "TargetTargetFrame" then
                if not UnitExists("targettarget") then
                    frame:Hide()
                    return
                else
                    frame:Show()
                end
            end

            -- Health
            local curhp, maxhp = UnitHealth(unit), UnitHealthMax(unit)
            frame.healthBar:SetMinMaxValues(0, maxhp)
            frame.healthBar:SetValue(curhp)
            frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
            frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
            local hpPct = nil
            pcall(function() hpPct = (maxhp and maxhp > 0) and math.floor((curhp / maxhp) * 100) or 0 end)
            local healthStr = string.format("%s / %s (%s%%)", tostring(curhp or 0), tostring(maxhp or 0), tostring(hpPct or 0))
            frame.healthBar.text:SetText(healthStr)

            -- Power
            local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
            frame.powerBar:SetMinMaxValues(0, maxpp)
            frame.powerBar:SetValue(curpp)
            frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
            frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
            local powerStr = string.format("%s / %s", tostring(curpp or 0), tostring(maxpp or 0))
            frame.powerBar.text:SetText(powerStr)

            -- Info
            if frame.infoBar then
                frame.infoBar.text:SetFont(LSM:Fetch("font", i.font), i.fontSize, i.fontOutline)
                frame.infoBar.text:SetTextColor(unpack(i.fontColor or {1,1,1,1}))
                local name = UnitName(unit) or ""
                local level = UnitLevel(unit) or ""
                local _, class = UnitClass(unit)
                class = class or ""
                local infoStr = string.format("%s %s %s", name, level, class)
                frame.infoBar.text:SetText(infoStr)
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


        function UnitFrames:PLAYER_TARGET_CHANGED()
            if self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
            if self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
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

        function UnitFrames:UNIT_TARGET(event, unit)
            if unit == "target" and self.db.profile.showTargetTarget then
                self:UpdateUnitFrame("TargetTargetFrame", "targettarget")
            end
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
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
            self:RegisterEvent("UNIT_TARGET")
            -- Only now call PLAYER_ENTERING_WORLD logic
            self:PLAYER_ENTERING_WORLD()
        end

        function UnitFrames:GetOptions()
            -- Helper: Safe number
            -- Remove tag parsing helpers; use direct formatting functions instead

            -- Helper: Tag parsing for text overlays (safe for secret values)
            local function ParseTags(str, unit)
                local curhp = UnitHealth(unit)
                local maxhp = UnitHealthMax(unit)
                local curpp = UnitPower(unit)
                local maxpp = UnitPowerMax(unit)
                -- Only use the always-safe gsub loop, no pre-replacement
                return (str:gsub("%[(.-)%]", function(tag)
                    -- Built-in tags
                    if tag == "curhp" then return safe(curhp) end
                    if tag == "maxhp" then return safe(maxhp) end
                    if tag == "curpp" then return safe(curpp) end
                    if tag == "maxpp" then return safe(maxpp) end
                    if tag == "name" then return safe(UnitName(unit)) end
                    if tag == "level" then return safe(UnitLevel(unit)) end
                    if tag == "class" then local _, class = UnitClass(unit); return safe(class) end
                    -- Custom tag functions
                    local ok, value = pcall(function()
                        if tagFuncs[tag] then
                            return tagFuncs[tag](unit)
                        end
                        return nil
                    end)
                    if not ok then return "" end
                    return safe(value)
                end))
            end

            -- Hide Blizzard frames if custom frames are enabled
            local function SetBlizzardFramesHidden(self)
                if self.db.profile.showPlayer and PlayerFrame then PlayerFrame:Hide(); PlayerFrame:UnregisterAllEvents(); PlayerFrame:Hide() end
                if self.db.profile.showTarget and TargetFrame then TargetFrame:Hide(); TargetFrame:UnregisterAllEvents(); TargetFrame:Hide() end
                if self.db.profile.showTargetTarget and TargetFrameToT then TargetFrameToT:Hide(); TargetFrameToT:UnregisterAllEvents(); TargetFrameToT:Hide() end
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
                    position = { point = "CENTER", x = 0, y = -200 }, -- Player
                    targetPosition = { point = "TOPLEFT", x = 320, y = 0 }, -- Target
                    totPosition = { point = "TOP", x = 0, y = -20 }, -- Target of Target
                    health = {
                        enabled = true, -- NEW
                        width = 220, height = 24,
                        color = {0.2, 0.8, 0.2, 1},
                        bgColor = {0, 0, 0, 0.5},
                        font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                        text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                        texture = "Flat"
                    },
                    power = {
                        enabled = true, -- NEW
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
                local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
                local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

                -- Use SecureUnitButtonTemplate for all unit frames
                local frameType = "Button"
                local template = "SecureUnitButtonTemplate,BackdropTemplate"
                local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
                frame:SetSize(width, totalHeight)
                -- Ensure anchorTo is always a frame, never a string
                local myPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
                local relTo = (type(anchorTo) == "table" and anchorTo) or UIParent
                local relPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
                local px = x or (db.position and db.position.x) or 0
                local py = y or (db.position and db.position.y) or 0
                frame:SetPoint(myPoint, relTo, relPoint, px, py)
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

                local yOffset = 0
                if h.enabled then
                    local healthBar = CreateBar(frame, h, yOffset)
                    healthBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
                    frame.healthBar = healthBar
                    yOffset = yOffset - h.height - spacing
                end
                if p.enabled then
                    local powerBar = CreateBar(frame, p, yOffset)
                    frame.powerBar = powerBar
                    yOffset = yOffset - p.height - spacing
                end
                if i.enabled then
                    local infoBar = CreateBar(frame, i, yOffset)
                    frame.infoBar = infoBar
                end

                -- Make all frames secure unit buttons for click targeting
                if key == "PlayerFrame" then
                    frame:SetAttribute("unit", "player")
                    frame:SetAttribute("type", "target")
                    frame:RegisterForClicks("AnyUp")
                elseif key == "TargetFrame" then
                    frame:SetAttribute("unit", "target")
                    frame:SetAttribute("type", "target")
                    frame:RegisterForClicks("AnyUp")
                elseif key == "TargetTargetFrame" then
                    frame:SetAttribute("unit", "targettarget")
                    frame:SetAttribute("type", "target")
                    frame:RegisterForClicks("AnyUp")
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
                local db = self.db.profile
                local anchorTo = UIParent
                local pos = db.targetPosition or { point = "TOPLEFT", x = 320, y = 0 }
                CreateUnitFrame(self, "TargetFrame", "target", anchorTo, pos.point, pos.point, pos.x, pos.y)
            end

            function UnitFrames:CreateTargetTargetFrame()
                if not self.db.profile.showTargetTarget then return end
                local db = self.db.profile
                local anchorTo = UIParent
                local pos = db.totPosition or { point = "TOP", x = 0, y = -20 }
                CreateUnitFrame(self, "TargetTargetFrame", "targettarget", anchorTo, pos.point, pos.point, pos.x, pos.y)
            end

            -- Update all bars and text

            function UnitFrames:UpdateUnitFrame(key, unit)
                local db = self.db.profile
                local frame = frames[key]
                if not frame then return end
                local h, p, i = db.health, db.power, db.info

                -- Special logic for TargetFrame: only show if target exists
                if key == "TargetFrame" then
                    if not UnitExists("target") then
                        frame:Hide()
                        return
                    else
                        frame:Show()
                    end
                end
                -- Special logic for Target of Target: only show if targettarget exists
                if key == "TargetTargetFrame" then
                    if not UnitExists("targettarget") then
                        frame:Hide()
                        return
                    else
                        frame:Show()
                    end
                end

                -- Health
                local curhp, maxhp = UnitHealth(unit), UnitHealthMax(unit)
                frame.healthBar:SetMinMaxValues(0, maxhp)
                frame.healthBar:SetValue(curhp)
                frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
                frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
                local hpPct = nil
                pcall(function() hpPct = (maxhp and maxhp > 0) and math.floor((curhp / maxhp) * 100) or 0 end)
                local healthStr = string.format("%s / %s (%s%%)", tostring(curhp or 0), tostring(maxhp or 0), tostring(hpPct or 0))
                frame.healthBar.text:SetText(healthStr)

                -- Power
                local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
                frame.powerBar:SetMinMaxValues(0, maxpp)
                frame.powerBar:SetValue(curpp)
                frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
                frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
                local powerStr = string.format("%s / %s", tostring(curpp or 0), tostring(maxpp or 0))
                frame.powerBar.text:SetText(powerStr)

                -- Info
                if frame.infoBar then
                    frame.infoBar.text:SetFont(LSM:Fetch("font", i.font), i.fontSize, i.fontOutline)
                    frame.infoBar.text:SetTextColor(unpack(i.fontColor or {1,1,1,1}))
                    local name = UnitName(unit) or ""
                    local level = UnitLevel(unit) or ""
                    local _, class = UnitClass(unit)
                    class = class or ""
                    local infoStr = string.format("%s %s %s", name, level, class)
                    frame.infoBar.text:SetText(infoStr)
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


            function UnitFrames:PLAYER_TARGET_CHANGED()
                if self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
                if self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
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

            function UnitFrames:UNIT_TARGET(event, unit)
                if unit == "target" and self.db.profile.showTargetTarget then
                    self:UpdateUnitFrame("TargetTargetFrame", "targettarget")
                end
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
                self:RegisterEvent("PLAYER_TARGET_CHANGED")
                self:RegisterEvent("UNIT_TARGET")
                -- Only now call PLAYER_ENTERING_WORLD logic
                self:PLAYER_ENTERING_WORLD()
            end

            function UnitFrames:GetOptions()
                -- Helper: Safe number
                -- Remove tag parsing helpers; use direct formatting functions instead

                -- Helper: Tag parsing for text overlays (safe for secret values)
                local function ParseTags(str, unit)
                    local curhp = UnitHealth(unit)
                    local maxhp = UnitHealthMax(unit)
                    local curpp = UnitPower(unit)
                    local maxpp = UnitPowerMax(unit)
                    -- Only use the always-safe gsub loop, no pre-replacement
                    return (str:gsub("%[(.-)%]", function(tag)
                        -- Built-in tags
                        if tag == "curhp" then return safe(curhp) end
                        if tag == "maxhp" then return safe(maxhp) end
                        if tag == "curpp" then return safe(curpp) end
                        if tag == "maxpp" then return safe(maxpp) end
                        if tag == "name" then return safe(UnitName(unit)) end
                        if tag == "level" then return safe(UnitLevel(unit)) end
                        if tag == "class" then local _, class = UnitClass(unit); return safe(class) end
                        -- Custom tag functions
                        local ok, value = pcall(function()
                            if tagFuncs[tag] then
                                return tagFuncs[tag](unit)
                            end
                            return nil
                        end)
                        if not ok then return "" end
                        return safe(value)
                    end))
                end

                -- Hide Blizzard frames if custom frames are enabled
                local function SetBlizzardFramesHidden(self)
                    if self.db.profile.showPlayer and PlayerFrame then PlayerFrame:Hide(); PlayerFrame:UnregisterAllEvents(); PlayerFrame:Hide() end
                    if self.db.profile.showTarget and TargetFrame then TargetFrame:Hide(); TargetFrame:UnregisterAllEvents(); TargetFrame:Hide() end
                    if self.db.profile.showTargetTarget and TargetFrameToT then TargetFrameToT:Hide(); TargetFrameToT:UnregisterAllEvents(); TargetFrameToT:Hide() end
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
                        position = { point = "CENTER", x = 0, y = -200 }, -- Player
                        targetPosition = { point = "TOPLEFT", x = 320, y = 0 }, -- Target
                        totPosition = { point = "TOP", x = 0, y = -20 }, -- Target of Target
                        health = {
                            enabled = true, -- NEW
                            width = 220, height = 24,
                            color = {0.2, 0.8, 0.2, 1},
                            bgColor = {0, 0, 0, 0.5},
                            font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                            text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                            texture = "Flat"
                        },
                        power = {
                            enabled = true, -- NEW
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
                    local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
                    local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

                    -- Use SecureUnitButtonTemplate for all unit frames
                    local frameType = "Button"
                    local template = "SecureUnitButtonTemplate,BackdropTemplate"
                    local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
                    frame:SetSize(width, totalHeight)
                    -- Ensure anchorTo is always a frame, never a string
                    local myPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
                    local relTo = (type(anchorTo) == "table" and anchorTo) or UIParent
                    local relPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
                    local px = x or (db.position and db.position.x) or 0
                    local py = y or (db.position and db.position.y) or 0
                    frame:SetPoint(myPoint, relTo, relPoint, px, py)
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

                    local yOffset = 0
                    if h.enabled then
                        local healthBar = CreateBar(frame, h, yOffset)
                        healthBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
                        frame.healthBar = healthBar
                        yOffset = yOffset - h.height - spacing
                    end
                    if p.enabled then
                        local powerBar = CreateBar(frame, p, yOffset)
                        frame.powerBar = powerBar
                        yOffset = yOffset - p.height - spacing
                    end
                    if i.enabled then
                        local infoBar = CreateBar(frame, i, yOffset)
                        frame.infoBar = infoBar
                    end

                    -- Make all frames secure unit buttons for click targeting
                    if key == "PlayerFrame" then
                        frame:SetAttribute("unit", "player")
                        frame:SetAttribute("type", "target")
                        frame:RegisterForClicks("AnyUp")
                    elseif key == "TargetFrame" then
                        frame:SetAttribute("unit", "target")
                        frame:SetAttribute("type", "target")
                        frame:RegisterForClicks("AnyUp")
                    elseif key == "TargetTargetFrame" then
                        frame:SetAttribute("unit", "targettarget")
                        frame:SetAttribute("type", "target")
                        frame:RegisterForClicks("AnyUp")
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
                    local db = self.db.profile
                    local anchorTo = UIParent
                    local pos = db.targetPosition or { point = "TOPLEFT", x = 320, y = 0 }
                    CreateUnitFrame(self, "TargetFrame", "target", anchorTo, pos.point, pos.point, pos.x, pos.y)
                end

                function UnitFrames:CreateTargetTargetFrame()
                    if not self.db.profile.showTargetTarget then return end
                    local db = self.db.profile
                    local anchorTo = UIParent
                    local pos = db.totPosition or { point = "TOP", x = 0, y = -20 }
                    CreateUnitFrame(self, "TargetTargetFrame", "targettarget", anchorTo, pos.point, pos.point, pos.x, pos.y)
                end

                -- Update all bars and text

                function UnitFrames:UpdateUnitFrame(key, unit)
                    local db = self.db.profile
                    local frame = frames[key]
                    if not frame then return end
                    local h, p, i = db.health, db.power, db.info

                    -- Special logic for TargetFrame: only show if target exists
                    if key == "TargetFrame" then
                        if not UnitExists("target") then
                            frame:Hide()
                            return
                        else
                            frame:Show()
                        end
                    end
                    -- Special logic for Target of Target: only show if targettarget exists
                    if key == "TargetTargetFrame" then
                        if not UnitExists("targettarget") then
                            frame:Hide()
                            return
                        else
                            frame:Show()
                        end
                    end

                    -- Health
                    local curhp, maxhp = UnitHealth(unit), UnitHealthMax(unit)
                    frame.healthBar:SetMinMaxValues(0, maxhp)
                    frame.healthBar:SetValue(curhp)
                    frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
                    frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
                    local hpPct = nil
                    pcall(function() hpPct = (maxhp and maxhp > 0) and math.floor((curhp / maxhp) * 100) or 0 end)
                    local healthStr = string.format("%s / %s (%s%%)", tostring(curhp or 0), tostring(maxhp or 0), tostring(hpPct or 0))
                    frame.healthBar.text:SetText(healthStr)

                    -- Power
                    local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
                    frame.powerBar:SetMinMaxValues(0, maxpp)
                    frame.powerBar:SetValue(curpp)
                    frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
                    frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
                    local powerStr = string.format("%s / %s", tostring(curpp or 0), tostring(maxpp or 0))
                    frame.powerBar.text:SetText(powerStr)

                    -- Info
                    if frame.infoBar then
                        frame.infoBar.text:SetFont(LSM:Fetch("font", i.font), i.fontSize, i.fontOutline)
                        frame.infoBar.text:SetTextColor(unpack(i.fontColor or {1,1,1,1}))
                        local name = UnitName(unit) or ""
                        local level = UnitLevel(unit) or ""
                        local _, class = UnitClass(unit)
                        class = class or ""
                        local infoStr = string.format("%s %s %s", name, level, class)
                        frame.infoBar.text:SetText(infoStr)
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


                function UnitFrames:PLAYER_TARGET_CHANGED()
                    if self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
                    if self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
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

                function UnitFrames:UNIT_TARGET(event, unit)
                    if unit == "target" and self.db.profile.showTargetTarget then
                        self:UpdateUnitFrame("TargetTargetFrame", "targettarget")
                    end
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
                    self:RegisterEvent("PLAYER_TARGET_CHANGED")
                    self:RegisterEvent("UNIT_TARGET")
                    -- Only now call PLAYER_ENTERING_WORLD logic
                    self:PLAYER_ENTERING_WORLD()
                end

                function UnitFrames:GetOptions()
                    -- Helper: Safe number
                    -- Remove tag parsing helpers; use direct formatting functions instead

                    -- Helper: Tag parsing for text overlays (safe for secret values)
                    local function ParseTags(str, unit)
                        local curhp = UnitHealth(unit)
                        local maxhp = UnitHealthMax(unit)
                        local curpp = UnitPower(unit)
                        local maxpp = UnitPowerMax(unit)
                        -- Only use the always-safe gsub loop, no pre-replacement
                        return (str:gsub("%[(.-)%]", function(tag)
                            -- Built-in tags
                            if tag == "curhp" then return safe(curhp) end
                            if tag == "maxhp" then return safe(maxhp) end
                            if tag == "curpp" then return safe(curpp) end
                            if tag == "maxpp" then return safe(maxpp) end
                            if tag == "name" then return safe(UnitName(unit)) end
                            if tag == "level" then return safe(UnitLevel(unit)) end
                            if tag == "class" then local _, class = UnitClass(unit); return safe(class) end
                            -- Custom tag functions
                            local ok, value = pcall(function()
                                if tagFuncs[tag] then
                                    return tagFuncs[tag](unit)
                                end
                                return nil
                            end)
                            if not ok then return "" end
                            return safe(value)
                        end))
                    end

                    -- Hide Blizzard frames if custom frames are enabled
                    local function SetBlizzardFramesHidden(self)
                        if self.db.profile.showPlayer and PlayerFrame then PlayerFrame:Hide(); PlayerFrame:UnregisterAllEvents(); PlayerFrame:Hide() end
                        if self.db.profile.showTarget and TargetFrame then TargetFrame:Hide(); TargetFrame:UnregisterAllEvents(); TargetFrame:Hide() end
                        if self.db.profile.showTargetTarget and TargetFrameToT then TargetFrameToT:Hide(); TargetFrameToT:UnregisterAllEvents(); TargetFrameToT:Hide() end
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
                            position = { point = "CENTER", x = 0, y = -200 }, -- Player
                            targetPosition = { point = "TOPLEFT", x = 320, y = 0 }, -- Target
                            totPosition = { point = "TOP", x = 0, y = -20 }, -- Target of Target
                            health = {
                                enabled = true, -- NEW
                                width = 220, height = 24,
                                color = {0.2, 0.8, 0.2, 1},
                                bgColor = {0, 0, 0, 0.5},
                                font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                                text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                                texture = "Flat"
                            },
                            power = {
                                enabled = true, -- NEW
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
                        local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
                        local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

                        -- Use SecureUnitButtonTemplate for all unit frames
                        local frameType = "Button"
                        local template = "SecureUnitButtonTemplate,BackdropTemplate"
                        local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
                        frame:SetSize(width, totalHeight)
                        -- Ensure anchorTo is always a frame, never a string
                        local myPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
                        local relTo = (type(anchorTo) == "table" and anchorTo) or UIParent
                        local relPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
                        local px = x or (db.position and db.position.x) or 0
                        local py = y or (db.position and db.position.y) or 0
                        frame:SetPoint(myPoint, relTo, relPoint, px, py)
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

                        local yOffset = 0
                        if h.enabled then
                            local healthBar = CreateBar(frame, h, yOffset)
                            healthBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
                            frame.healthBar = healthBar
                            yOffset = yOffset - h.height - spacing
                        end
                        if p.enabled then
                            local powerBar = CreateBar(frame, p, yOffset)
                            frame.powerBar = powerBar
                            yOffset = yOffset - p.height - spacing
                        end
                        if i.enabled then
                            local infoBar = CreateBar(frame, i, yOffset)
                            frame.infoBar = infoBar
                        end

                        -- Make all frames secure unit buttons for click targeting
                        if key == "PlayerFrame" then
                            frame:SetAttribute("unit", "player")
                            frame:SetAttribute("type", "target")
                            frame:RegisterForClicks("AnyUp")
                        elseif key == "TargetFrame" then
                            frame:SetAttribute("unit", "target")
                            frame:SetAttribute("type", "target")
                            frame:RegisterForClicks("AnyUp")
                        elseif key == "TargetTargetFrame" then
                            frame:SetAttribute("unit", "targettarget")
                            frame:SetAttribute("type", "target")
                            frame:RegisterForClicks("AnyUp")
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
                        local db = self.db.profile
                        local anchorTo = UIParent
                        local pos = db.targetPosition or { point = "TOPLEFT", x = 320, y = 0 }
                        CreateUnitFrame(self, "TargetFrame", "target", anchorTo, pos.point, pos.point, pos.x, pos.y)
                    end

                    function UnitFrames:CreateTargetTargetFrame()
                        if not self.db.profile.showTargetTarget then return end
                        local db = self.db.profile
                        local anchorTo = UIParent
                        local pos = db.totPosition or { point = "TOP", x = 0, y = -20 }
                        CreateUnitFrame(self, "TargetTargetFrame", "targettarget", anchorTo, pos.point, pos.point, pos.x, pos.y)
                    end

                    -- Update all bars and text

                    function UnitFrames:UpdateUnitFrame(key, unit)
                        local db = self.db.profile
                        local frame = frames[key]
                        if not frame then return end
                        local h, p, i = db.health, db.power, db.info

                        -- Special logic for TargetFrame: only show if target exists
                        if key == "TargetFrame" then
                            if not UnitExists("target") then
                                frame:Hide()
                                return
                            else
                                frame:Show()
                            end
                        end
                        -- Special logic for Target of Target: only show if targettarget exists
                        if key == "TargetTargetFrame" then
                            if not UnitExists("targettarget") then
                                frame:Hide()
                                return
                            else
                                frame:Show()
                            end
                        end

                        -- Health
                        local curhp, maxhp = UnitHealth(unit), UnitHealthMax(unit)
                        frame.healthBar:SetMinMaxValues(0, maxhp)
                        frame.healthBar:SetValue(curhp)
                        frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
                        frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
                        local hpPct = nil
                        pcall(function() hpPct = (maxhp and maxhp > 0) and math.floor((curhp / maxhp) * 100) or 0 end)
                        local healthStr = string.format("%s / %s (%s%%)", tostring(curhp or 0), tostring(maxhp or 0), tostring(hpPct or 0))
                        frame.healthBar.text:SetText(healthStr)

                        -- Power
                        local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
                        frame.powerBar:SetMinMaxValues(0, maxpp)
                        frame.powerBar:SetValue(curpp)
                        frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
                        frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
                        local powerStr = string.format("%s / %s", tostring(curpp or 0), tostring(maxpp or 0))
                        frame.powerBar.text:SetText(powerStr)

                        -- Info
                        if frame.infoBar then
                            frame.infoBar.text:SetFont(LSM:Fetch("font", i.font), i.fontSize, i.fontOutline)
                            frame.infoBar.text:SetTextColor(unpack(i.fontColor or {1,1,1,1}))
                            local name = UnitName(unit) or ""
                            local level = UnitLevel(unit) or ""
                            local _, class = UnitClass(unit)
                            class = class or ""
                            local infoStr = string.format("%s %s %s", name, level, class)
                            frame.infoBar.text:SetText(infoStr)
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


                    function UnitFrames:PLAYER_TARGET_CHANGED()
                        if self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
                        if self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
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

                    function UnitFrames:UNIT_TARGET(event, unit)
                        if unit == "target" and self.db.profile.showTargetTarget then
                            self:UpdateUnitFrame("TargetTargetFrame", "targettarget")
                        end
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
                        self:RegisterEvent("PLAYER_TARGET_CHANGED")
                        self:RegisterEvent("UNIT_TARGET")
                        -- Only now call PLAYER_ENTERING_WORLD logic
                        self:PLAYER_ENTERING_WORLD()
                    end

                    function UnitFrames:GetOptions()
                        -- Helper: Safe number
                        -- Remove tag parsing helpers; use direct formatting functions instead

                        -- Helper: Tag parsing for text overlays (safe for secret values)
                        local function ParseTags(str, unit)
                            local curhp = UnitHealth(unit)
                            local maxhp = UnitHealthMax(unit)
                            local curpp = UnitPower(unit)
                            local maxpp = UnitPowerMax(unit)
                            -- Only use the always-safe gsub loop, no pre-replacement
                            return (str:gsub("%[(.-)%]", function(tag)
                                -- Built-in tags
                                if tag == "curhp" then return safe(curhp) end
                                if tag == "maxhp" then return safe(maxhp) end
                                if tag == "curpp" then return safe(curpp) end
                                if tag == "maxpp" then return safe(maxpp) end
                                if tag == "name" then return safe(UnitName(unit)) end
                                if tag == "level" then return safe(UnitLevel(unit)) end
                                if tag == "class" then local _, class = UnitClass(unit); return safe(class) end
                                -- Custom tag functions
                                local ok, value = pcall(function()
                                    if tagFuncs[tag] then
                                        return tagFuncs[tag](unit)
                                    end
                                    return nil
                                end)
                                if not ok then return "" end
                                return safe(value)
                            end))
                        end

                        -- Hide Blizzard frames if custom frames are enabled
                        local function SetBlizzardFramesHidden(self)
                            if self.db.profile.showPlayer and PlayerFrame then PlayerFrame:Hide(); PlayerFrame:UnregisterAllEvents(); PlayerFrame:Hide() end
                            if self.db.profile.showTarget and TargetFrame then TargetFrame:Hide(); TargetFrame:UnregisterAllEvents(); TargetFrame:Hide() end
                            if self.db.profile.showTargetTarget and TargetFrameToT then TargetFrameToT:Hide(); TargetFrameToT:UnregisterAllEvents(); TargetFrameToT:Hide() end
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
                                position = { point = "CENTER", x = 0, y = -200 }, -- Player
                                targetPosition = { point = "TOPLEFT", x = 320, y = 0 }, -- Target
                                totPosition = { point = "TOP", x = 0, y = -20 }, -- Target of Target
                                health = {
                                    enabled = true, -- NEW
                                    width = 220, height = 24,
                                    color = {0.2, 0.8, 0.2, 1},
                                    bgColor = {0, 0, 0, 0.5},
                                    font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                                    text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                                    texture = "Flat"
                                },
                                power = {
                                    enabled = true, -- NEW
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
                            local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
                            local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

                            -- Use SecureUnitButtonTemplate for all unit frames
                            local frameType = "Button"
                            local template = "SecureUnitButtonTemplate,BackdropTemplate"
                            local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
                            frame:SetSize(width, totalHeight)
                            -- Ensure anchorTo is always a frame, never a string
                            local myPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
                            local relTo = (type(anchorTo) == "table" and anchorTo) or UIParent
                            local relPoint = anchorPoint or (db.position and db.position.point) or "CENTER"
                            local px = x or (db.position and db.position.x) or 0
                            local py = y or (db.position and db.position.y) or 0
                            frame:SetPoint(myPoint, relTo, relPoint, px, py)
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

                            local yOffset = 0
                            if h.enabled then
                                local healthBar = CreateBar(frame, h, yOffset)
                                healthBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
                                frame.healthBar = healthBar
                                yOffset = yOffset - h.height - spacing