-- Modular UnitFrames: Load separate option files from Frames subfolder
-- The Player, Target, and TargetTarget option files are loaded via the TOC and available globally.


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
                    text = "[name] [level] [class]", textPos = "CENTER",
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
                    text = "[name] [level] [class]", textPos = "CENTER",
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
                    text = "[name] [level] [class]", textPos = "CENTER",
                    texture = "Flat"
                }
            }
        }
    }

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
                    -- DEBUG: Red border for frame boundary visualization. Remove for release!
                    frame.debugBorder = frame:CreateTexture(nil, "OVERLAY")
                    frame.debugBorder:SetAllPoints()
                    frame.debugBorder:SetColorTexture(1,0,0,0.5)
                    frame.debugBorder:SetBlendMode("ADD")
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
                        local infoBar = CreateBar(frame, i, 0)
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
                    local frame = frames[key]
                    if not frame then return end
                    local frameKey = (key == "PlayerFrame" and "player") or (key == "TargetFrame" and "target") or (key == "TargetTargetFrame" and "targettarget")
                    local h, p, i = db[frameKey].health, db[frameKey].power, db[frameKey].info

                    if key == "TargetFrame" then
                        if not UnitExists("target") then
                            frame:Hide()
                            return
                        else
                            frame:Show()
                        end
                    end
                    if key == "TargetTargetFrame" then
                        if not UnitExists("targettarget") then
                            frame:Hide()
                            return
                        else
                            frame:Show()
                        end
                    end

                    local curhp, maxhp = UnitHealth(unit), UnitHealthMax(unit)
                    -- Class color logic
                    local _, classToken = UnitClass(unit)
                    local classColor = RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken] or { r = 1, g = 1, b = 1 }

                    -- Health Bar
                    frame.healthBar:SetMinMaxValues(0, maxhp)
                    frame.healthBar:SetValue(curhp)
                    frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
                    if h.fontClassColor then
                        frame.healthBar.text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
                    else
                        frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
                    end
                    if h.classColor then
                        frame.healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
                    else
                        frame.healthBar:SetStatusBarColor(unpack(h.color or {0.2,0.8,0.2,1}))
                    end
                    local safeCurhp = 0
                    if type(curhp) == "number" then
                        safeCurhp = curhp
                    elseif type(curhp) == "string" then
                        safeCurhp = tonumber(curhp) or 0
                    end
                    local safeMaxhp = 0
                    if type(maxhp) == "number" then
                        safeMaxhp = maxhp
                    elseif type(maxhp) == "string" then
                        safeMaxhp = tonumber(maxhp) or 0
                    end
                    local hpPct = 0
                    if safeMaxhp > 0 then
                        hpPct = math.floor((safeCurhp / safeMaxhp) * 100)
                    end
                    local healthFormat = h.text or "[curhp] / [maxhp] ([perhp]%)"
                    local healthStr = tostring(healthFormat)
                    local name = tostring(UnitName(unit) or "")
                    local level = tostring(UnitLevel(unit) or "")
                    local className, classToken = UnitClass(unit)
                    className = tostring(className or "")
                    classToken = tostring(classToken or "")
                    healthStr = healthStr:gsub("%[name%]", name)
                    healthStr = healthStr:gsub("%[level%]", level)
                    healthStr = healthStr:gsub("%[class%]", className ~= '' and className or classToken)
                    healthStr = healthStr:gsub("%[curhp%]", tostring(safeCurhp))
                    healthStr = healthStr:gsub("%[maxhp%]", tostring(safeMaxhp))
                    healthStr = healthStr:gsub("%[perhp%]", tostring(hpPct))
                    local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
                    local safeCurpp = tonumber(curpp) or 0
                    local safeMaxpp = tonumber(maxpp) or 0
                    local ppPct = 0
                    if safeMaxpp > 0 then
                        ppPct = math.floor((safeCurpp / safeMaxpp) * 100)
                    end
                    healthStr = healthStr:gsub("%[curpp%]", tostring(safeCurpp))
                    healthStr = healthStr:gsub("%[maxpp%]", tostring(safeMaxpp))
                    healthStr = healthStr:gsub("%[perpp%]", tostring(ppPct))
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
                    local powerStr = tostring(powerFormat)
                    powerStr = powerStr:gsub("%[name%]", name)
                    powerStr = powerStr:gsub("%[level%]", level)
                    powerStr = powerStr:gsub("%[class%]", className ~= '' and className or classToken)
                    powerStr = powerStr:gsub("%[curhp%]", tostring(safeCurhp))
                    powerStr = powerStr:gsub("%[maxhp%]", tostring(safeMaxhp))
                    powerStr = powerStr:gsub("%[perhp%]", tostring(hpPct))
                    powerStr = powerStr:gsub("%[curpp%]", tostring(safeCurpp))
                    powerStr = powerStr:gsub("%[maxpp%]", tostring(safeMaxpp))
                    powerStr = powerStr:gsub("%[perpp%]", tostring(ppPct))
                    frame.powerBar.text:SetText(powerStr)

                    -- Info Bar
                    if frame.infoBar then
                        frame.infoBar.text:SetFont(LSM:Fetch("font", i.font), i.fontSize, i.fontOutline)
                        if i.fontClassColor then
                            frame.infoBar.text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
                        else
                            frame.infoBar.text:SetTextColor(unpack(i.fontColor or {1,1,1,1}))
                        end
                        if i.classColor then
                            frame.infoBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 1)
                        else
                            frame.infoBar:SetStatusBarColor(unpack(i.color or {0.8,0.8,0.2,1}))
                        end
                        local infoFormat = i.text or "[name] [level] [class]"
                        local infoStr = tostring(infoFormat)
                        infoStr = infoStr:gsub("%[name%]", name)
                        infoStr = infoStr:gsub("%[level%]", level)
                        infoStr = infoStr:gsub("%[class%]", className ~= '' and className or classToken)
                        infoStr = infoStr:gsub("%[curhp%]", tostring(safeCurhp))
                        infoStr = infoStr:gsub("%[maxhp%]", tostring(safeMaxhp))
                        infoStr = infoStr:gsub("%[perhp%]", tostring(hpPct))
                        infoStr = infoStr:gsub("%[curpp%]", tostring(safeCurpp))
                        infoStr = infoStr:gsub("%[maxpp%]", tostring(safeMaxpp))
                        infoStr = infoStr:gsub("%[perpp%]", tostring(ppPct))
                        frame.infoBar.text:SetText(infoStr)
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