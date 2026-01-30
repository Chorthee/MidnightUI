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
local LSM = LibStub("LibSharedMedia-3.0")

local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UnitFrames = MidnightUI:NewModule("UnitFrames", "AceEvent-3.0", "AceHook-3.0")
_G.UnitFrames = UnitFrames
local LSM = LibStub("LibSharedMedia-3.0")

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
                    bgColor = {0, 0, 0, 0.5},
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 14, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
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
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 12, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = "[curpp] / [maxpp]", textPos = "CENTER",
                    texture = "Flat"
                },
                info = {
                    enabled = true, width = 220, height = 10,
                    color = {0.8, 0.8, 0.2, 1},
                    bgColor = {0, 0, 0, 0.5},
                    font = (MidnightUI and MidnightUI.db and MidnightUI.db.profile and MidnightUI.db.profile.theme and MidnightUI.db.profile.theme.font) or "Friz Quadrata TT", fontSize = 10, fontOutline = "OUTLINE", fontColor = {1,1,1,1},
                    text = nil, textPos = nil, -- migrated to textCenter
                    textLeft = nil,
                    textCenter = "[name] [level] [class]",
                    textRight = nil,
                    texture = "Flat"
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
                    if self.db.profile.showPlayer and PlayerFrame then PlayerFrame:Hide(); PlayerFrame:UnregisterAllEvents(); PlayerFrame:Hide() end
                    if self.db.profile.showTarget and TargetFrame then TargetFrame:Hide(); TargetFrame:UnregisterAllEvents(); TargetFrame:Hide() end
                    if self.db.profile.showTargetTarget and TargetFrameToT then TargetFrameToT:Hide(); TargetFrameToT:UnregisterAllEvents(); TargetFrameToT:Hide() end
                end

                local function HookBlizzardPlayerFrame(self)
                    if PlayerFrame and not PlayerFrame._MidnightUIHooked then
                        hooksecurefunc(PlayerFrame, "Show", function()
                            if self.db and self.db.profile and self.db.profile.showPlayer then PlayerFrame:Hide() end
                        end)
                        PlayerFrame._MidnightUIHooked = true
                    end
                end

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
                        bar.bg:SetColorTexture(unpack(opts.bgColor or {0,0,0,0.5}))
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
                    if frames[key] then
                        frames[key]:Hide()
                        frames[key]:SetParent(nil)
                        frames[key] = nil
                    end
                    local db = self.db.profile
                    local spacing = db.spacing
                    local frameKey = (key == "PlayerFrame" and "player") or (key == "TargetFrame" and "target") or (key == "TargetTargetFrame" and "targettarget")
                    local frameDB = db[frameKey]
                    local h, p, i = frameDB.health, frameDB.power, frameDB.info
                    local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
                    local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

                    local frameType = "Button"
                    local template = "SecureUnitButtonTemplate,BackdropTemplate"
                    local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
                    frame:SetSize(width, totalHeight)

                    -- Use posX/posY if present, else fallback to position table, else 0
                    local px = frameDB.posX or (frameDB.position and frameDB.position.x) or 0
                    local py = frameDB.posY or (frameDB.position and frameDB.position.y) or 0
                    local myPoint = anchorPoint or (frameDB.position and frameDB.position.point) or "CENTER"
                    local relTo = (type(anchorTo) == "table" and anchorTo) or UIParent
                    local relPoint = anchorPoint or (frameDB.position and frameDB.position.point) or "CENTER"
                    frame:SetPoint(myPoint, relTo, relPoint, px, py)
                    frame:SetMovable(true)
                    frame:EnableMouse(true)
                    frame:SetClampedToScreen(true)
                    frame:SetFrameStrata("HIGH")
                    frame:Show()
                    MidnightUI:SkinFrame(frame)
                    -- DEBUG: Red border for frame boundary visualization. Disabled for release.
                    -- frame.debugBorder = frame:CreateTexture(nil, "OVERLAY")
                    -- frame.debugBorder:SetAllPoints()
                    -- frame.debugBorder:SetColorTexture(1,0,0,0.5)
                    -- frame.debugBorder:SetBlendMode("ADD")
                    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("[MidnightUI] Created frame: "..key.." at "..(px)..","..(py).." size "..width.."x"..totalHeight) end

                    -- Drag to move if unlocked
                    frame:RegisterForDrag("LeftButton")
                    frame:SetScript("OnDragStart", function(self)
                        if frameDB.movable then self:StartMoving() end
                    end)
                    frame:SetScript("OnDragStop", function(self)
                        self:StopMovingOrSizing()
                        local point, _, _, xOfs, yOfs = self:GetPoint()
                        frameDB.posX = xOfs or 0
                        frameDB.posY = yOfs or 0
                    end)

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

                -- Reset position function for PlayerFrame
                function UnitFrames:ResetUnitFramePosition(key)
                    local db = self.db.profile
                    local frameKey = (key == "PlayerFrame" and "player") or (key == "TargetFrame" and "target") or (key == "TargetTargetFrame" and "targettarget")
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


                function UnitFrames:UpdateUnitFrame(key, unit)
                    local db = self.db.profile
                    local frameKey = (key == "PlayerFrame" and "player") or (key == "TargetFrame" and "target") or (key == "TargetTargetFrame" and "targettarget")
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
                        if ok and val then safeCurhp = val end
                    end
                    local safeMaxhp = 0
                    if UnitHealthMax then
                        local ok, val = pcall(UnitHealthMax, unit)
                        if ok and val then safeMaxhp = val end
                    end
                    local safeCurpp = 0
                    if UnitPower then
                        local ok, val = pcall(UnitPower, unit)
                        if ok and val then safeCurpp = val end
                    end
                    local safeMaxpp = 0
                    if UnitPowerMax then
                        local ok, val = pcall(UnitPowerMax, unit)
                        if ok and val then safeMaxpp = val end
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
                        if hpPct then
                            healthStr = string.format("%d / %d (%d%%)", safeCurhp, safeMaxhp, hpPct)
                        else
                            healthStr = string.format("%d / %d", safeCurhp, safeMaxhp)
                        end
                    elseif showCur and showMax then
                        healthStr = string.format("%d / %d", safeCurhp, safeMaxhp)
                    elseif showCur and showPct then
                        if hpPct then
                            healthStr = string.format("%d (%d%%)", safeCurhp, hpPct)
                        else
                            healthStr = string.format("%d", safeCurhp)
                        end
                    elseif showCur then
                        healthStr = string.format("%d", safeCurhp)
                    elseif showMax then
                        healthStr = string.format("%d", safeMaxhp)
                    elseif showPct then
                        if hpPct then
                            healthStr = string.format("%d%%", hpPct)
                        else
                            healthStr = ""
                        end
                    else
                        -- fallback: just show current
                        healthStr = string.format("%d", safeCurhp)
                    end
                    frame.healthBar.text:SetText(healthStr)

                    -- Power Bar
                    local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
                    frame.powerBar:SetMinMaxValues(0, maxpp)
                    frame.powerBar:SetValue(curpp)
                    frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
                    if p.fontClassColor then
                        frame.powerBar.text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
                    else
                        frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
                    end
                    -- Use Blizzard default color if not overridden
                    local powerColor = p.color
                    if not p._userSetColor and (not p.color or (p.color[1] == 0.2 and p.color[2] == 0.4 and p.color[3] == 0.8)) then
                        powerColor = GetPowerTypeColor(unit)
                    end
                    frame.powerBar:SetStatusBarColor(unpack(powerColor or {0.2,0.4,0.8,1}))
                    local powerFormat = p.text or "[curpp] / [maxpp]"
                    -- Defensive: ensure all values are strings, never nil
                    local function safeStr(val)
                        if type(val) == "string" then
                            return val
                        elseif type(val) == "number" then
                            return tostring(val)
                        elseif val == nil or val == false then
                            return "0"
                        else
                            return tostring(val)
                        end
                    end
                    local safeName = safeStr(name)
                    local safeLevel = safeStr(level)
                    local safeClass = safeStr((className ~= '' and className) or classToken)
                    local safeCurppStr = safeStr(safeCurpp)
                    local safeMaxppStr = safeStr(safeMaxpp)
                    local safePpPctStr = safeStr(ppPct)
                    -- Defensive: re-assign all safe*Str variables right before use to avoid nil propagation
                    -- Only assign once, right before use, and never shadow with nil
                    local powerStr = tostring(powerFormat)
                    powerStr = powerStr:gsub("%[name%]", safeStr(name))
                    powerStr = powerStr:gsub("%[level%]", safeStr(level))
                    powerStr = powerStr:gsub("%[class%]", safeStr((className ~= '' and className) or classToken))
                    powerStr = powerStr:gsub("%[curhp%]", safeStr(safeCurhp))
                    powerStr = powerStr:gsub("%[maxhp%]", safeStr(safeMaxhp))
                    powerStr = powerStr:gsub("%[perhp%]", safeStr(hpPct))
                    powerStr = powerStr:gsub("%[curpp%]", safeStr(safeCurpp))
                    powerStr = powerStr:gsub("%[maxpp%]", safeStr(safeMaxpp))
                    powerStr = powerStr:gsub("%[perpp%]", safeStr(ppPct))
                    frame.powerBar.text:SetText(powerStr)
                    powerStr = powerStr:gsub("%[name%]", safeName)
                    powerStr = powerStr:gsub("%[level%]", safeLevel)
                    powerStr = powerStr:gsub("%[class%]", safeClass)
                    powerStr = powerStr:gsub("%[curhp%]", safeCurhpStr)
                    powerStr = powerStr:gsub("%[maxhp%]", safeMaxhpStr)
                    powerStr = powerStr:gsub("%[perhp%]", safeHpPctStr)
                    powerStr = powerStr:gsub("%[curpp%]", safeCurppStr)
                    powerStr = powerStr:gsub("%[maxpp%]", safeMaxppStr)
                    powerStr = powerStr:gsub("%[perpp%]", safePpPctStr)
                    frame.powerBar.text:SetText(powerStr)

                    -- Info Bar (remove tag parsing for health percent)
                    if frame.infoBar then
                        local infoBar = frame.infoBar
                        local font, fontSize, fontOutline = LSM:Fetch("font", i.font), i.fontSize, i.fontOutline
                        local color = i.fontClassColor and {classColor.r, classColor.g, classColor.b, 1} or (i.fontColor or {1,1,1,1})
                        if infoBar.textLeft and infoBar.textCenter and infoBar.textRight then
                            infoBar.textLeft:SetFont(font, fontSize, fontOutline)
                            infoBar.textLeft:SetTextColor(unpack(color))
                            infoBar.textCenter:SetFont(font, fontSize, fontOutline)
                            infoBar.textCenter:SetTextColor(unpack(color))
                            infoBar.textRight:SetFont(font, fontSize, fontOutline)
                            infoBar.textRight:SetTextColor(unpack(color))
                            if i.classColor then
                                infoBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
                            else
                                infoBar:SetStatusBarColor(unpack(i.color or {0.8,0.8,0.2,1}))
                            end
                            -- Only replace tags that are not health percent
                            local function parseTagsNoPercent(fmt)
                                if not fmt or fmt == "" then return "" end
                                local s = tostring(fmt)
                                s = s:gsub("%[name%]", name)
                                s = s:gsub("%[level%]", level)
                                s = s:gsub("%[class%]", className ~= '' and className or classToken)
                                s = s:gsub("%[curhp%]", tostring(safeCurhp))
                                s = s:gsub("%[maxhp%]", tostring(safeMaxhp))
                                s = s:gsub("%[curpp%]", tostring(safeCurpp))
                                s = s:gsub("%[maxpp%]", tostring(safeMaxpp))
                                s = s:gsub("%[perpp%]", tostring(ppPct))
                                return s
                            end
                            -- Insert health percent robustly
                            local function insertPercent(str)
                                if str:find("%[perhp%]") then
                                    if hpPct then
                                        return str:gsub("%[perhp%]", tostring(hpPct))
                                    else
                                        return str:gsub("%[perhp%]", "")
                                    end
                                end
                                return str
                            end
                            infoBar.textLeft:SetText(insertPercent(parseTagsNoPercent(i.textLeft or "")))
                            infoBar.textCenter:SetText(insertPercent(parseTagsNoPercent(i.textCenter or "")))
                            infoBar.textRight:SetText(insertPercent(parseTagsNoPercent(i.textRight or "")))
                        elseif infoBar.text then
                            infoBar.text:SetFont(font, fontSize, fontOutline)
                            infoBar.text:SetTextColor(unpack(color))
                            if i.classColor then
                                infoBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
                            else
                                infoBar:SetStatusBarColor(unpack(i.color or {0.8,0.8,0.2,1}))
                            end
                            local infoFormat = i.text or "[name] [level] [class]"
                            local infoStr = parseTagsNoPercent(infoFormat)
                            if infoFormat:find("%[perhp%]") then
                                if hpPct then
                                    infoStr = infoStr:gsub("%[perhp%]", tostring(hpPct))
                                else
                                    infoStr = infoStr:gsub("%[perhp%]", "")
                                end
                            end
                            infoBar.text:SetText(infoStr)
                        end
                    end
                end

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