if not LibStub then return end
local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UnitFrames = MidnightUI and MidnightUI:NewModule("UnitFrames", "AceEvent-3.0", "AceHook-3.0")
if not UnitFrames then return end
_G.UnitFrames = UnitFrames
local LSM = LibStub("LibSharedMedia-3.0")


-- Utility: Sanitize a color table to ensure all values are plain numbers (not secret values)
local function SanitizeColorTable(color, fallback)
    fallback = fallback or {1, 1, 1, 1}
    if type(color) ~= "table" then return fallback end
    local r = tonumber(color[1]) or fallback[1] or 1
    local g = tonumber(color[2]) or fallback[2] or 1
    local b = tonumber(color[3]) or fallback[3] or 1
    local a = tonumber(color[4]) or fallback[4] or 1
    return {r, g, b, a}
end
-- Helper: Health percent with 12.0+ API compatibility (QUI-style)
local tocVersion = tonumber((select(4, GetBuildInfo()))) or 0
local function GetHealthPct(unit, usePredicted)
    if tocVersion >= 120000 and type(UnitHealthPercent) == "function" then
        local ok, pct
        if CurveConstants and CurveConstants.ScaleTo100 then
            ok, pct = pcall(UnitHealthPercent, unit, usePredicted, CurveConstants.ScaleTo100)
        end
        if not ok or pct == nil then
            ok, pct = pcall(UnitHealthPercent, unit, usePredicted)
        end
        if ok and pct ~= nil then
            return pct
        end
    end
    if UnitHealth and UnitHealthMax then
        local cur = UnitHealth(unit)
        local max = UnitHealthMax(unit)
        if cur and max and max > 0 then
            local ok, pct = pcall(function() return (cur / max) * 100 end)
            if ok then return pct end
        end
    end
    return nil
end

-- Helper: Power percent with 12.0+ API compatibility (QUI-style)
local function GetPowerPct(unit, powerType, usePredicted)
    if tocVersion >= 120000 and type(UnitPowerPercent) == "function" then
        local ok, pct
        if CurveConstants and CurveConstants.ScaleTo100 then
            ok, pct = pcall(UnitPowerPercent, unit, powerType, usePredicted, CurveConstants.ScaleTo100)
        end
        if not ok or pct == nil then
            ok, pct = pcall(UnitPowerPercent, unit, powerType, usePredicted)
        end
        if ok and pct ~= nil then
            return pct
        end
    end
    local cur = UnitPower and UnitPower(unit, powerType) or 0
    local max = UnitPowerMax and UnitPowerMax(unit, powerType) or 0
    local calcOk, result = pcall(function()
        if cur and max and max > 0 then
            return (cur / max) * 100
        end
        return nil
    end)
    if calcOk and result then
        return result
    end
    return nil
end


-- Blizzard power type colors
local POWER_TYPE_COLORS = {
    MANA = {0.00, 0.44, 0.87, 1},
    RAGE = {0.78, 0.21, 0.21, 1},
    FOCUS = {1.00, 0.50, 0.25, 1},
    ENERGY = {1.00, 0.85, 0.10, 1},
    RUNIC_POWER = {0.00, 0.82, 1.00, 1},
    FURY = {0.788, 0.259, 0.992, 1},
    PAIN = {1.00, 0.61, 0.00, 1},
}

local function GetPowerTypeColor(unit)
    local powerType, powerToken = UnitPowerType(unit)
    if powerToken and POWER_TYPE_COLORS[powerToken] then
        return POWER_TYPE_COLORS[powerToken]
    end
    return {0.2, 0.4, 0.8, 1} -- fallback (blue)
end


local frames = {}

-- Move HookBlizzardPlayerFrame definition above its first use

local function SetBlizzardFramesHidden(self)
    if self.db.profile.showPlayer and PlayerFrame then
        UnregisterStateDriver(PlayerFrame, "visibility")
        RegisterStateDriver(PlayerFrame, "visibility", "hide")
        PlayerFrame:UnregisterAllEvents()
    end
    if self.db.profile.showTarget and TargetFrame then
        UnregisterStateDriver(TargetFrame, "visibility")
        RegisterStateDriver(TargetFrame, "visibility", "hide")
        TargetFrame:UnregisterAllEvents()
    end
    -- Do not forcibly hide TargetFrame here; let the secure driver in CreateTargetFrame control its visibility
    if self.db.profile.showTargetTarget and TargetFrameToT then
        UnregisterStateDriver(TargetFrameToT, "visibility")
        RegisterStateDriver(TargetFrameToT, "visibility", "hide")
        TargetFrameToT:UnregisterAllEvents()
    end
end

local function HookBlizzardPlayerFrame(self)
    if PlayerFrame and not PlayerFrame._MidnightUIHooked then
        hooksecurefunc(PlayerFrame, "Show", function()
            if self.db and self.db.profile and self.db.profile.showPlayer then PlayerFrame:Hide() end
        end)
        PlayerFrame._MidnightUIHooked = true
    end
end

-- ...existing code...

function UnitFrames:GetOptions()
    return {
        name = "Unit Frames",
        type = "group",
        childGroups = "tab",
        args = {
            player = {
                name = "Player",
                type = "group",
                order = 1,
                args = self.GetPlayerOptions_Real and self:GetPlayerOptions_Real().args or {},
            },
            target = {
                name = "Target",
                type = "group",
                order = 2,
                args = self.GetTargetOptions_Real and self:GetTargetOptions_Real().args or {},
            },
            targettarget = {
                name = "Target of Target",
                type = "group",
                order = 3,
                args = self.GetTargetTargetOptions_Real and self:GetTargetTargetOptions_Real().args or {},
            },
            focus = {
                name = "Focus",
                type = "group",
                order = 4,
                args = self.GetFocusOptions_Real and self:GetFocusOptions_Real().args or {},
            },
        },
    }
end

function UnitFrames:GetPlayerOptions()
    if self.GetPlayerOptions_Real then
        return self:GetPlayerOptions_Real()
    end
    return nil
end

    function UnitFrames:PLAYER_ENTERING_WORLD()
        if not self.db or not self.db.profile then
            return
        end
        HookBlizzardPlayerFrame(self)
        if self.db.profile.showPlayer then self:CreatePlayerFrame() end
        if self.db.profile.showTarget then self:CreateTargetFrame() end
        if self.db.profile.showTargetTarget then self:CreateTargetTargetFrame() end
        if self.db.profile.showFocus then self:CreateFocusFrame() end
        SetBlizzardFramesHidden(self)
    end


    function UnitFrames:PLAYER_TARGET_CHANGED()
        if self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
        if self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
        if self.db.profile.showFocus then self:UpdateUnitFrame("FocusFrame", "focus") end
    end

    function UnitFrames:UNIT_HEALTH(event, unit)
        if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
        if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
        if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
        if unit == "focus" and self.db.profile.showFocus then self:UpdateUnitFrame("FocusFrame", "focus") end
        SetBlizzardFramesHidden(self)
    end

    function UnitFrames:UNIT_POWER_UPDATE(event, unit)
        if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
        if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
        if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
        if unit == "focus" and self.db.profile.showFocus then self:UpdateUnitFrame("FocusFrame", "focus") end
        SetBlizzardFramesHidden(self)
    end

    function UnitFrames:UNIT_DISPLAYPOWER(event, unit)
        if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
        if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
        if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
        if unit == "focus" and self.db.profile.showFocus then self:UpdateUnitFrame("FocusFrame", "focus") end
        SetBlizzardFramesHidden(self)
    end

    function UnitFrames:UNIT_TARGET(event, unit)
        if unit == "target" and self.db.profile.showTargetTarget then
            self:UpdateUnitFrame("TargetTargetFrame", "targettarget")
        end
        if unit == "focus" and self.db.profile.showFocus then
            self:UpdateUnitFrame("FocusFrame", "focus")
        end
    end

    local defaults = {
        profile = {
            enabled = true,
            showPlayer = true,
            showTarget = true,
            showTargetTarget = true,
            spacing = 4,
            player = {
                position = { point = "CENTER", x = 0, y = -200 },
                health = {
                    enabled = true,
                    width = 220, height = 24,
                    color = {0.2, 0.8, 0.2, 1},
                    bgColor = {0, 0, 0, 0},
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                    textPresets = {
                        { name = "Current / Max (Percent)", value = "[curhp] / [maxhp] ([perhp]%)" },
                        { name = "Current Only", value = "[curhp]" },
                        { name = "Max Only", value = "[maxhp]" },
                        { name = "Percent Only", value = "[perhp]%" },
                    },
                    texture = "Blizzard Raid Bar"
                },
                power = {
                    enabled = true,
                    width = 220, height = 12,
                    color = {0.2, 0.4, 0.8, 1},
                    bgColor = {0.2, 0.4, 0.8, 0.2},
                    classColor = false,
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 12, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = "[curpp] / [maxpp]", textPos = "CENTER",
                    texture = "Blizzard Raid Bar"
                },
                info = {
                    enabled = true, width = 220, height = 10,
                    color = {0.8, 0.8, 0.2, 1},
                    bgColor = {0, 0, 0, 1},
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 10, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = nil, textPos = nil, -- migrated to textCenter
                    textLeft = nil,
                    textCenter = "[name] [level] [class]",
                    textRight = nil,
                    texture = "Blizzard Raid Bar"
                }
            },
            target = {
                position = { point = "TOPLEFT", x = 320, y = 0 },
                health = {
                    enabled = true,
                    width = 220, height = 24,
                    color = {0.2, 0.8, 0.2, 1},
                    bgColor = {0, 0, 0, 0.5},
                    font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                    textPresets = {
                        { name = "Current / Max (Percent)", value = "[curhp] / [maxhp] ([perhp]%)" },
                        { name = "Current Only", value = "[curhp]" },
                        { name = "Max Only", value = "[maxhp]" },
                        { name = "Percent Only", value = "[perhp]%" },
                    },
                    texture = "Flat"
                },
                power = {
                    enabled = true,
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
                    text = nil, textPos = nil, -- migrated to textCenter
                    textLeft = nil,
                    textCenter = "[name] [level] [class]",
                    textRight = nil,
                    texture = "Flat"
                }
            },
            targettarget = {
                position = { point = "TOP", x = 0, y = -20 },
                health = {
                    enabled = true,
                    width = 220, height = 24,
                    color = {0.2, 0.8, 0.2, 1},
                    bgColor = {0, 0, 0, 0.5},
                    font = "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                    textPresets = {
                        { name = "Current / Max (Percent)", value = "[curhp] / [maxhp] ([perhp]%)" },
                        { name = "Current Only", value = "[curhp]" },
                        { name = "Max Only", value = "[maxhp]" },
                        { name = "Percent Only", value = "[perhp]%" },
                    },
                    texture = "Flat"
                },
                power = {
                    enabled = true,
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
                    text = nil, textPos = nil, -- migrated to textCenter
                    textLeft = nil,
                    textCenter = "[name] [level] [class]",
                    textRight = nil,
                    texture = "Flat"
                }
            },
            focus = {
                position = { point = "CENTER", x = 0, y = -100 },
                health = {
                    enabled = true,
                    width = 220, height = 24,
                    color = {0.2, 0.8, 0.2, 1},
                    bgColor = {0, 0, 0, 0},
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = "[curhp] / [maxhp] ([perhp]%)", textPos = "CENTER",
                    textPresets = {
                        { name = "Current / Max (Percent)", value = "[curhp] / [maxhp] ([perhp]%)" },
                        { name = "Current Only", value = "[curhp]" },
                        { name = "Max Only", value = "[maxhp]" },
                        { name = "Percent Only", value = "[perhp]%" },
                    },
                    texture = "Blizzard Raid Bar"
                },
                power = {
                    enabled = true,
                    width = 220, height = 12,
                    color = {0.2, 0.4, 0.8, 1},
                    bgColor = {0.2, 0.4, 0.8, 0.2},
                    classColor = false,
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 12, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = "[curpp] / [maxpp]", textPos = "CENTER",
                    texture = "Blizzard Raid Bar"
                },
                info = {
                    enabled = true, width = 220, height = 10,
                    color = {0.8, 0.8, 0.2, 1},
                    bgColor = {0, 0, 0, 1},
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 10, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = nil, textPos = nil, -- migrated to textCenter
                    textLeft = nil,
                    textCenter = "[name] [level] [class]",
                    textRight = nil,
                    texture = "Blizzard Raid Bar"
                }
            }
        }
    }

UnitFrames.defaults = defaults

-- Migrate legacy info bar text to new left/center/right fields for backward compatibility

local function MigrateInfoBarText(opts)
    if opts and opts.info then
        -- Migrate legacy text field
        if opts.info.text and not (opts.info.textLeft or opts.info.textCenter or opts.info.textRight) then
            opts.info.textCenter = opts.info.text
            opts.info.text = nil
        end
        if opts.info.textPos then opts.info.textPos = nil end
        -- Ensure left/center/right fields are always strings
        if opts.info.textLeft == nil then opts.info.textLeft = "" end
        if opts.info.textCenter == nil then opts.info.textCenter = "" end
        if opts.info.textRight == nil then opts.info.textRight = "" end
    end
end

-- Call migration for all default unit frame options
do
    local defaults = UnitFrames and UnitFrames.defaults or nil
    if defaults then
        MigrateInfoBarText(defaults.player)
        MigrateInfoBarText(defaults.target)
        MigrateInfoBarText(defaults.targettarget)
    end
end

                local function SetBlizzardFramesHidden(self)
                    if self.db.profile.showPlayer and PlayerFrame then
                        UnregisterStateDriver(PlayerFrame, "visibility")
                        RegisterStateDriver(PlayerFrame, "visibility", "hide")
                        PlayerFrame:UnregisterAllEvents()
                    end
                    if self.db.profile.showTarget and TargetFrame then
                        UnregisterStateDriver(TargetFrame, "visibility")
                        RegisterStateDriver(TargetFrame, "visibility", "hide")
                        TargetFrame:UnregisterAllEvents()
                    end
                    -- Do not forcibly hide TargetFrame here; let the secure driver in CreateTargetFrame control its visibility
                    if self.db.profile.showTargetTarget and TargetFrameToT then
                        UnregisterStateDriver(TargetFrameToT, "visibility")
                        RegisterStateDriver(TargetFrameToT, "visibility", "hide")
                        TargetFrameToT:UnregisterAllEvents()
                    end
                end



                local function CreateBar(parent, opts, yOffset)
                    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
                    bar:SetStatusBarTexture(LSM:Fetch("statusbar", opts.texture or "Flat"))
                    local safeColor = SanitizeColorTable(opts.color, {0.2, 0.8, 0.2, 1})
                    bar:SetStatusBarColor(unpack(safeColor))
                    bar:SetMinMaxValues(0, 1)
                    bar:SetValue(1)
                    bar:SetHeight(opts.height)
                    bar:SetWidth(opts.width)
                    bar:SetPoint("LEFT", 0, 0)
                    bar:SetPoint("RIGHT", 0, 0)
                    bar:SetPoint("TOP", 0, yOffset)
                    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
                    bar.bg:SetAllPoints()
                    -- Use Bar settings for InfoBar background if this is the InfoBar
                    if opts._infoBar then
                        -- Use per-frame InfoBar alpha if available (Player frame only for now)
                        local parentFrame = (parent and parent.GetName and parent:GetName()) or ""
                        local infoAlpha = nil
                        if parentFrame == "MidnightUI_PlayerFrame" and UnitFrames and UnitFrames.db and UnitFrames.db.profile and UnitFrames.db.profile.player and UnitFrames.db.profile.player.info then
                            infoAlpha = UnitFrames.db.profile.player.info.alpha or (UnitFrames.db.profile.player.info.color and UnitFrames.db.profile.player.info.color[4]) or 1
                        end
                        local Bar = MidnightUI:GetModule("Bar", true)
                        local barTexture, barAlpha
                        if Bar and Bar.db and Bar.db.profile and Bar.db.profile.bars and Bar.db.profile.bars["MainBar"] then
                            local barSettings = Bar.db.profile.bars["MainBar"]
                            barTexture = LSM:Fetch("statusbar", barSettings.texture or "Flat")
                            barAlpha = infoAlpha or barSettings.alpha or 0.6
                            local c = barSettings.color or {r=0.1,g=0.1,b=0.1}
                            bar.bg:SetTexture(barTexture)
                            bar.bg:SetVertexColor(c.r, c.g, c.b, barAlpha)
                        else
                            local alpha = infoAlpha or (opts.bgColor and opts.bgColor[4]) or 0.5
                            local bg = opts.bgColor or {0,0,0,0.5}
                            bar.bg:SetColorTexture(bg[1], bg[2], bg[3], alpha)
                        end
                    else
                        -- Always use solid black for health bar background
                        -- For power bar, use foreground color with 20% alpha for background
                        if opts and opts.bgColor and opts.bgColor[4] == 0.2 then
                            local fg = SanitizeColorTable(opts.color, {0.2, 0.4, 0.8, 1})
                            bar.bg:SetColorTexture(fg[1], fg[2], fg[3], 0.2)
                        elseif opts and opts.bgColor and opts.bgColor[1] == 0 and opts.bgColor[2] == 0 and opts.bgColor[3] == 0 then
                            local safeBG = SanitizeColorTable(opts.bgColor, {0, 0, 0, 0})
                            bar.bg:SetColorTexture(safeBG[1], safeBG[2], safeBG[3], safeBG[4])
                        else
                            local safeBG = SanitizeColorTable(opts.bgColor, {0,0,0,0.5})
                            bar.bg:SetColorTexture(safeBG[1], safeBG[2], safeBG[3], safeBG[4])
                        end
                    end
                    -- Info bar: create three FontStrings for left, center, right
                    if opts._infoBar then
                        bar.textLeft = bar:CreateFontString(nil, "OVERLAY")
                        bar.textLeft:SetPoint("LEFT", 4, 0)
                        bar.textLeft:SetJustifyH("LEFT")
                        bar.textCenter = bar:CreateFontString(nil, "OVERLAY")
                        bar.textCenter:SetPoint("CENTER", 0, 0)
                        bar.textCenter:SetJustifyH("CENTER")
                        bar.textRight = bar:CreateFontString(nil, "OVERLAY")
                        bar.textRight:SetPoint("RIGHT", -4, 0)
                        bar.textRight:SetJustifyH("RIGHT")
                    else
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
                    end
                    return bar
                end


                local function CreateUnitFrame(self, key, unit, anchor, anchorTo, anchorPoint, x, y)
                                        -- DEBUG: Print when creating highlight and border
                                        if DEFAULT_CHAT_FRAME then
                                            DEFAULT_CHAT_FRAME:AddMessage("[MidnightUI][DEBUG] Creating highlight for " .. tostring(key))
                                        end
                                            if DEFAULT_CHAT_FRAME then
                                                DEFAULT_CHAT_FRAME:AddMessage("[MidnightUI][DEBUG] Created highlight and border for " .. tostring(key))
                                            end
                    if frames[key] then
                        frames[key]:Hide()
                        frames[key]:SetParent(nil)
                        frames[key] = nil
                    end
                    local db = self.db.profile
                    local spacing = db.spacing
                    local frameKey = (key == "PlayerFrame" and "player") or (key == "TargetFrame" and "target") or (key == "TargetTargetFrame" and "targettarget") or (key == "FocusFrame" and "focus")
                    local frameDB = db[frameKey]
                    local h, p, i = frameDB.health, frameDB.power, frameDB.info
                    local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
                    local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

                    local frameType = "Button"
                    local template = "SecureUnitButtonTemplate,BackdropTemplate"
                    local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
                    frame:SetSize(width, totalHeight)

                    -- Use saved anchor/relative points if present, else fallback to CENTER
                    local myPoint = frameDB.anchorPoint or (anchorPoint or (frameDB.position and frameDB.position.point) or "CENTER")
                    local relPoint = frameDB.relativePoint or (anchorPoint or (frameDB.position and frameDB.position.point) or "CENTER")
                    local px = frameDB.posX or (frameDB.position and frameDB.position.x) or 0
                    local py = frameDB.posY or (frameDB.position and frameDB.position.y) or 0
                    local relTo = (type(anchorTo) == "table" and anchorTo) or UIParent
                    frame:SetPoint(myPoint, relTo, relPoint, px, py)
                    frame:SetFrameStrata("HIGH")
                    frame:Show()
                    MidnightUI:SkinFrame(frame)

                    -- Enable drag-and-drop movement for unit frames
                    local Movable = MidnightUI:GetModule("Movable", true)
                    if Movable and (key == "PlayerFrame" or key == "TargetFrame" or key == "TargetTargetFrame" or key == "FocusFrame") then
                        -- Remove any old highlight
                        if frame.movableHighlightFrame then
                            frame.movableHighlightFrame:Hide()
                            frame.movableHighlightFrame:SetParent(nil)
                            frame.movableHighlightFrame = nil
                        end
                        -- Create a dedicated child frame above all content
                        frame.movableHighlightFrame = CreateFrame("Frame", nil, frame)
                        frame.movableHighlightFrame:SetAllPoints()
                        frame.movableHighlightFrame:SetFrameStrata(frame:GetFrameStrata())
                        frame.movableHighlightFrame:SetFrameLevel(frame:GetFrameLevel() + 50)
                        -- Green highlight (hidden by default)
                        frame.movableHighlight = frame.movableHighlightFrame:CreateTexture(nil, "OVERLAY")
                        frame.movableHighlight:SetAllPoints()
                        frame.movableHighlight:SetColorTexture(0, 1, 0, 0.2) -- semi-transparent green
                        -- Add a semi-transparent red border
                        frame.movableHighlightBorder = frame.movableHighlightFrame:CreateTexture(nil, "OVERLAY")
                        frame.movableHighlightBorder:SetPoint("TOPLEFT", frame.movableHighlight, "TOPLEFT", -2, 2)
                        frame.movableHighlightBorder:SetPoint("BOTTOMRIGHT", frame.movableHighlight, "BOTTOMRIGHT", 2, -2)
                        frame.movableHighlightBorder:SetColorTexture(1, 0, 0, 0.7)
                        frame.movableHighlightFrame:Hide() -- Hide by default

                        -- Always call MakeFrameDraggable to ensure registration (after highlight creation)
                        Movable:MakeFrameDraggable(frame, function(_, x, y)
                            local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
                            frameDB.anchorPoint = point or "CENTER"
                            frameDB.relativePoint = relativePoint or "CENTER"
                            frameDB.posX = xOfs or 0
                            frameDB.posY = yOfs or 0
                        end)
                        -- Add compact <^Rv> nudge arrows
                        Movable:CreateContainerArrows(frame, frameDB, function()
                            -- Reset callback: center the frame
                            frameDB.anchorPoint = "CENTER"
                            frameDB.relativePoint = "CENTER"
                            frameDB.posX = 0
                            frameDB.posY = 0
                            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                        end)
                    end
                    -- DEBUG: Red border for frame boundary visualization. Disabled for release.
                    -- frame.debugBorder = frame:CreateTexture(nil, "OVERLAY")
                    -- frame.debugBorder:SetAllPoints()
                    -- frame.debugBorder:SetColorTexture(1,0,0,0.5)
                    -- frame.debugBorder:SetBlendMode("ADD")


                    -- Remove legacy drag logic; handled by Movable:MakeFrameDraggable

                    -- Bar attachment logic
                    local yOffset = 0
                    local barRefs = {}
                    if h.enabled then
                        local healthBar = CreateBar(frame, h, yOffset)
                        healthBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
                        frame.healthBar = healthBar
                        barRefs.health = healthBar
                        yOffset = yOffset - h.height - spacing
                    end
                    if p.enabled then
                        local attachTo = (p.attachTo or "health")
                        local attachBar = (attachTo ~= "none" and barRefs[attachTo]) or frame
                        local powerBar = CreateBar(frame, p, 0)
                        if attachBar and attachBar ~= frame then
                            powerBar:SetPoint("TOP", attachBar, "BOTTOM", 0, -spacing)
                        else
                            powerBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
                            yOffset = yOffset - p.height - spacing
                        end
                        frame.powerBar = powerBar
                        barRefs.power = powerBar
                    end
                    if i.enabled then
                        local attachTo = (i.attachTo or "health")
                        local attachBar = (attachTo ~= "none" and barRefs[attachTo]) or frame
                        i._infoBar = true -- flag for CreateBar
                        local infoBar = CreateBar(frame, i, 0)
                        i._infoBar = nil
                        if attachBar and attachBar ~= frame then
                            infoBar:SetPoint("TOP", attachBar, "BOTTOM", 0, -spacing)
                        else
                            infoBar:SetPoint("TOP", frame, "TOP", 0, yOffset)
                        end
                        frame.infoBar = infoBar
                        barRefs.info = infoBar
                    end


                    if key == "PlayerFrame" then
                        frame:SetAttribute("unit", "player")
                        frame:SetAttribute("type", "target")
                        frame:SetAttribute("*type2", "togglemenu")
                        frame:RegisterForClicks("AnyUp")
                    elseif key == "TargetFrame" then
                        frame:SetAttribute("unit", "target")
                        frame:SetAttribute("type", "target")
                        frame:SetAttribute("*type2", "togglemenu")
                        frame:RegisterForClicks("AnyUp")
                    elseif key == "TargetTargetFrame" then
                        frame:SetAttribute("unit", "targettarget")
                        frame:SetAttribute("type", "target")
                        frame:SetAttribute("*type2", "togglemenu")
                        frame:RegisterForClicks("AnyUp")
                    elseif key == "FocusFrame" then
                        frame:SetAttribute("unit", "focus")
                        frame:SetAttribute("type", "target")
                        frame:SetAttribute("*type2", "togglemenu")
                        frame:RegisterForClicks("AnyUp")
                    end

                    frames[key] = frame
                    self:UpdateUnitFrame(key, unit)
                end

                -- Reset position function for PlayerFrame
                function UnitFrames:ResetUnitFramePosition(key)
                    local db = self.db.profile
                    local frameKey = (key == "PlayerFrame" and "player") or (key == "TargetFrame" and "target") or (key == "TargetTargetFrame" and "targettarget") or (key == "FocusFrame" and "focus")
                    if not db[frameKey] then return end
                    db[frameKey].posX = 0
                    db[frameKey].posY = 0
                    if frames[key] then
                        frames[key]:ClearAllPoints()
                        frames[key]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                    end
                    self:UpdateUnitFrame(key, frameKey)
                end

                function UnitFrames:CreatePlayerFrame()
                    if not self.db.profile.showPlayer then return end
                    -- Anchor PlayerFrame to CENTER
                    CreateUnitFrame(self, "PlayerFrame", "player", UIParent, "CENTER", "CENTER", self.db.profile.player.posX or 0, self.db.profile.player.posY or 0)
                    local frame = _G["MidnightUI_PlayerFrame"]
                    if frame then
                        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
                        local msg = string.format("[MidnightUI][DEBUG] PlayerFrame position: %s, %s, %s, %d, %d", tostring(point), tostring(relativeTo and relativeTo:GetName() or "nil"), tostring(relativePoint), xOfs or 0, yOfs or 0)
                        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
                    end
                end

                function UnitFrames:CreateTargetFrame()
                    if not self.db.profile.showTarget then return end
                    local db = self.db.profile
                    -- Anchor TargetFrame to CENTER
                    local anchorTo = UIParent
                    local posX = (db.target and db.target.posX) or 0
                    local posY = (db.target and db.target.posY) or 0
                    CreateUnitFrame(self, "TargetFrame", "target", anchorTo, "CENTER", "CENTER", posX, posY)
                    -- Only show TargetFrame if a target exists
                    local customTargetFrame = _G["MidnightUI_TargetFrame"]
                    if customTargetFrame then
                        customTargetFrame:Hide() -- Hide by default
                        UnregisterStateDriver(customTargetFrame, "visibility")
                        RegisterStateDriver(customTargetFrame, "visibility", "[@target,exists] show; hide")
                        local point, relativeTo, relativePoint, xOfs, yOfs = customTargetFrame:GetPoint()
                        local msg = string.format("[MidnightUI][DEBUG] TargetFrame position: %s, %s, %s, %d, %d", tostring(point), tostring(relativeTo and relativeTo:GetName() or "nil"), tostring(relativePoint), xOfs or 0, yOfs or 0)
                        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
                    end
                end

                function UnitFrames:CreateTargetTargetFrame()
                    if not self.db.profile.showTargetTarget then return end
                    local db = self.db.profile
                    -- Anchor TargetTargetFrame to CENTER
                    local anchorTo = UIParent
                    local posX = (db.targettarget and db.targettarget.posX) or 0
                    local posY = (db.targettarget and db.targettarget.posY) or 0
                    CreateUnitFrame(self, "TargetTargetFrame", "targettarget", anchorTo, "CENTER", "CENTER", posX, posY)
                    -- Only show TargetTargetFrame if target has a target
                    local customToTFrame = _G["MidnightUI_TargetTargetFrame"]
                    if customToTFrame then
                        customToTFrame:Hide() -- Hide by default
                        UnregisterStateDriver(customToTFrame, "visibility")
                        RegisterStateDriver(customToTFrame, "visibility", "[@targettarget,exists] show; hide")
                        local point, relativeTo, relativePoint, xOfs, yOfs = customToTFrame:GetPoint()
                        local msg = string.format("[MidnightUI][DEBUG] TargetTargetFrame position: %s, %s, %s, %d, %d", tostring(point), tostring(relativeTo and relativeTo:GetName() or "nil"), tostring(relativePoint), xOfs or 0, yOfs or 0)
                        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
                    end
                end
                
                function UnitFrames:CreateFocusFrame()
                    if not self.db or not self.db.profile or not self.db.profile.showFocus then return end
                    CreateUnitFrame(self, "FocusFrame", "focus")
                end

                function UnitFrames:UpdateUnitFrame(key, unit)
                    local db = self.db.profile
                    local frameKey = (key == "PlayerFrame" and "player") or (key == "TargetFrame" and "target") or (key == "TargetTargetFrame" and "targettarget") or (key == "FocusFrame" and "focus")
                    local frameDB = db[frameKey]
                    if not frameDB then return end
                    local h, p, i = frameDB.health, frameDB.power, frameDB.info
                    local frame = frames[key]
                    if not frame then return end

                    -- Calculate health percent robustly (QUI-style)
                    local hpPct = GetHealthPct(unit)
                    if hpPct then
                        local ok, floored = pcall(math.floor, hpPct)
                        if ok and floored then
                            hpPct = floored
                        else
                            hpPct = nil
                        end
                    else
                        hpPct = nil
                    end

                    -- Calculate power percent robustly (QUI-style)
                    local ppPct = GetPowerPct(unit)
                    if ppPct then
                        local ok, floored = pcall(math.floor, ppPct)
                        if ok and floored then
                            ppPct = floored
                        else
                            ppPct = nil
                        end
                    else
                        ppPct = nil
                    end

                    -- Defensive: ensure all variables used in gsub are strings or numbers, never nil
                    local name = UnitName and UnitName(unit) or ""
                    local level = UnitLevel and UnitLevel(unit) or ""
                    local className = (UnitClass and select(1, UnitClass(unit))) or ""
                    local classToken = (UnitClass and select(2, UnitClass(unit))) or ""
                    local safeCurhp = 0
                    if UnitHealth then
                        local ok, val = pcall(UnitHealth, unit)
                        if ok and val ~= nil then safeCurhp = val else safeCurhp = 0 end
                    end
                    local safeMaxhp = 0
                    if UnitHealthMax then
                        local ok, val = pcall(UnitHealthMax, unit)
                        if ok and val ~= nil then safeMaxhp = val else safeMaxhp = 0 end
                    end
                    local safeCurpp = 0
                    if UnitPower then
                        local ok, val = pcall(UnitPower, unit)
                        if ok and val ~= nil then safeCurpp = val else safeCurpp = 0 end
                    end
                    local safeMaxpp = 0
                    if UnitPowerMax then
                        local ok, val = pcall(UnitPowerMax, unit)
                        if ok and val ~= nil then safeMaxpp = val else safeMaxpp = 0 end
                    end
                    if hpPct == nil then hpPct = 0 end
                    if ppPct == nil then ppPct = 0 end

                    -- Format health text directly, not using tag parsing
                    local healthStr = ""
                    local showCur = h.text and h.text:find("curhp")
                    local showMax = h.text and h.text:find("maxhp")
                    local showPct = h.text and h.text:find("perhp")
                    -- Default: show current / max (percent)
                    if showCur and showMax and showPct then
                        if hpPct ~= nil then
                            healthStr = string.format("%d / %d (%d%%)", safeCurhp or 0, safeMaxhp or 0, hpPct or 0)
                        else
                            healthStr = string.format("%d / %d", safeCurhp or 0, safeMaxhp or 0)
                        end
                    elseif showCur and showMax then
                        healthStr = string.format("%d / %d", safeCurhp or 0, safeMaxhp or 0)
                    elseif showCur and showPct then
                        if hpPct ~= nil then
                            healthStr = string.format("%d (%d%%)", safeCurhp or 0, hpPct or 0)
                        else
                            healthStr = string.format("%d", safeCurhp or 0)
                        end
                    elseif showCur then
                        healthStr = string.format("%d", safeCurhp or 0)
                    elseif showMax then
                        healthStr = string.format("%d", safeMaxhp or 0)
                    elseif showPct then
                        if hpPct ~= nil then
                            healthStr = string.format("%d%%", hpPct or 0)
                        else
                            healthStr = ""
                        end
                    else
                        -- fallback: just show current
                        healthStr = string.format("%d", safeCurhp or 0)
                    end

                    -- Update health bar fill to reflect current health
                    if frame.healthBar then
                        frame.healthBar:SetMinMaxValues(0, safeMaxhp or 0)
                        frame.healthBar:SetValue(safeCurhp or 0)
                        frame.healthBar.text:SetText(healthStr or "")
                    end

                    -- Set health bar color: class color if enabled, else hostility color, else custom/static color (no gradient, no arithmetic)
                    local colorSet = false
                    if h.classColor then
                        local _, classToken = UnitClass(unit)
                        if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
                            local classColorValue = RAID_CLASS_COLORS[classToken]
                            frame.healthBar:SetStatusBarColor(
                                tonumber(classColorValue.r) or 1,
                                tonumber(classColorValue.g) or 1,
                                tonumber(classColorValue.b) or 1,
                                1)
                            colorSet = true
                        end
                    elseif h.hostilityColor then
                        local reaction = UnitReaction(unit, "player")
                        if reaction then
                            if reaction >= 5 then
                                frame.healthBar:SetStatusBarColor(0.2, 0.8, 0.2, 1) -- Friendly (green)
                            elseif reaction == 4 then
                                frame.healthBar:SetStatusBarColor(1, 1, 0.2, 1) -- Neutral (yellow)
                            else
                                frame.healthBar:SetStatusBarColor(0.8, 0.2, 0.2, 1) -- Hostile (red)
                            end
                            colorSet = true
                        end
                    end
                    if not colorSet then
                        local c = SanitizeColorTable(h.color, {0.2, 0.2, 0.2, 1})
                        frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
                    end

                    -- Power Bar
                    local curpp = safeCurpp or 0
                    local maxpp = safeMaxpp or 0
                    if frame.powerBar then
                        frame.powerBar:SetMinMaxValues(0, maxpp)
                        frame.powerBar:SetValue(curpp)
                        frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
                        if p.fontClassColor and classColor and classColor.r then
                            frame.powerBar.text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
                        else
                            frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
                        end
                        -- Use Blizzard default color if not overridden
                        local powerColor = p.color
                        local useClassColor = p.classColor
                        local safePowerColor
                        if useClassColor then
                            local _, classToken = UnitClass(unit)
                            if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
                                local classColorValue = RAID_CLASS_COLORS[classToken]
                                safePowerColor = {
                                    tonumber(classColorValue.r) or 1,
                                    tonumber(classColorValue.g) or 1,
                                    tonumber(classColorValue.b) or 1,
                                    0.6
                                }
                                frame.powerBar:SetStatusBarColor(safePowerColor[1], safePowerColor[2], safePowerColor[3], safePowerColor[4])
                                if frame.powerBar.bg then
                                    frame.powerBar.bg:SetColorTexture(safePowerColor[1], safePowerColor[2], safePowerColor[3], 0.2)
                                end
                            else
                                safePowerColor = SanitizeColorTable(powerColor, {0.2,0.4,0.8,1})
                                frame.powerBar:SetStatusBarColor(safePowerColor[1], safePowerColor[2], safePowerColor[3], safePowerColor[4])
                            end
                        else
                            if not p._userSetColor and (not p.color or (p.color[1] == 0.2 and p.color[2] == 0.4 and p.color[3] == 0.8)) then
                                powerColor = GetPowerTypeColor(unit)
                            end
                            safePowerColor = SanitizeColorTable(powerColor, {0.2,0.4,0.8,1})
                            frame.powerBar:SetStatusBarColor(safePowerColor[1], safePowerColor[2], safePowerColor[3], safePowerColor[4])
                        end
                        -- Set static power bar text: current power percent
                        frame.powerBar.text:SetText(ppPct and (tostring(ppPct) .. "%") or "")
                    end

                    -- Set static info bar text: character name and level
                    if frame.infoBar then
                        local infoBar = frame.infoBar
                        local font, fontSize, fontOutline = LSM:Fetch("font", i.font), i.fontSize, i.fontOutline
                        local color
                        if i.fontClassColor and classColor and classColor.r and classColor.g and classColor.b then
                            color = {classColor.r, classColor.g, classColor.b, 1}
                        else
                            color = (i.fontColor or {1,1,1,1})
                        end
                        local infoText = name .. " " .. tostring(level)
                        if infoBar.textLeft and infoBar.textCenter and infoBar.textRight then
                            if infoBar.textLeft.SetFont and infoBar.textLeft.SetTextColor and infoBar.textLeft.SetText then
                                infoBar.textLeft:SetFont(font, fontSize, fontOutline)
                                infoBar.textLeft:SetTextColor(unpack(color))
                                infoBar.textLeft:SetText("")
                            end
                            if infoBar.textCenter.SetFont and infoBar.textCenter.SetTextColor and infoBar.textCenter.SetText then
                                infoBar.textCenter:SetFont(font, fontSize, fontOutline)
                                infoBar.textCenter:SetTextColor(unpack(color))
                                infoBar.textCenter:SetText(infoText)
                            end
                            if infoBar.textRight.SetFont and infoBar.textRight.SetTextColor and infoBar.textRight.SetText then
                                infoBar.textRight:SetFont(font, fontSize, fontOutline)
                                infoBar.textRight:SetTextColor(unpack(color))
                                infoBar.textRight:SetText("")
                            end
                        elseif infoBar.text and infoBar.text.SetFont and infoBar.text.SetTextColor and infoBar.text.SetText then
                            infoBar.text:SetFont(font, fontSize, fontOutline)
                            infoBar.text:SetTextColor(unpack(color))
                            infoBar.text:SetText(infoText)
                        end
                    end
                end



                function UnitFrames:PLAYER_TARGET_CHANGED()
                    if self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
                    if self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
                    if self.db.profile.showFocus then self:UpdateUnitFrame("FocusFrame", "focus") end
                end

                function UnitFrames:UNIT_HEALTH(event, unit)
                    if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
                    if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
                    if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
                    if unit == "focus" and self.db.profile.showFocus then self:UpdateUnitFrame("FocusFrame", "focus") end
                    SetBlizzardFramesHidden(self)
                end

                function UnitFrames:UNIT_POWER_UPDATE(event, unit)
                    if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
                    if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
                    if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
                    if unit == "focus" and self.db.profile.showFocus then self:UpdateUnitFrame("FocusFrame", "focus") end
                    SetBlizzardFramesHidden(self)
                end

                function UnitFrames:UNIT_DISPLAYPOWER(event, unit)
                    if unit == "player" and self.db.profile.showPlayer then self:UpdateUnitFrame("PlayerFrame", "player") end
                    if unit == "target" and self.db.profile.showTarget then self:UpdateUnitFrame("TargetFrame", "target") end
                    if unit == "targettarget" and self.db.profile.showTargetTarget then self:UpdateUnitFrame("TargetTargetFrame", "targettarget") end
                    if unit == "focus" and self.db.profile.showFocus then self:UpdateUnitFrame("FocusFrame", "focus") end
                    SetBlizzardFramesHidden(self)
                end

                function UnitFrames:UNIT_TARGET(event, unit)
                    if unit == "target" and self.db.profile.showTargetTarget then
                        self:UpdateUnitFrame("TargetTargetFrame", "targettarget")
                    end
                    if unit == "focus" and self.db.profile.showFocus then
                        self:UpdateUnitFrame("FocusFrame", "focus")
                    end
                end

                function UnitFrames:OnInitialize()
                    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
                    self:RegisterEvent("PLAYER_ENTERING_WORLD")
                end

                function UnitFrames:OnDBReady()
                    if not MidnightUI.db.profile.modules.unitframes then return end
                    self.db = MidnightUI.db:RegisterNamespace("UnitFrames", defaults)
                    self:RegisterEvent("UNIT_HEALTH")
                    self:RegisterEvent("UNIT_POWER_UPDATE")
                    self:RegisterEvent("UNIT_DISPLAYPOWER")
                    self:RegisterEvent("PLAYER_TARGET_CHANGED")
                    self:RegisterEvent("UNIT_TARGET")
                    self:PLAYER_ENTERING_WORLD()
                end

                function UnitFrames:GetPlayerOptions()
                    if self.GetPlayerOptions_Real then
                        return self:GetPlayerOptions_Real()
                    end
                    return nil
                end

                function UnitFrames:GetTargetOptions()
                    if self.GetTargetOptions_Real then
                        return self:GetTargetOptions_Real()
                    end
                    return nil
                end

                function UnitFrames:GetTargetTargetOptions()
                    if self.GetTargetTargetOptions_Real then
                        return self:GetTargetTargetOptions_Real()
                    end
                    return nil
                end