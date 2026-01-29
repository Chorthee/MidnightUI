-- Modular UnitFrames: Load separate option files

-- Modular UnitFrames: Load separate option files from Frames subfolder
-- The Player, Target, and TargetTarget option files are loaded via the TOC and available globally.

-- ...existing code...

-- target, tot, etc. should be added here as siblings, not nested
-- target = { ... },

local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UnitFrames = MidnightUI:NewModule("UnitFrames", "AceEvent-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

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
            position = { point = "CENTER", x = 0, y = -200 },
            targetPosition = { point = "TOPLEFT", x = 320, y = 0 },
            totPosition = { point = "TOP", x = 0, y = -20 },
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
                    if frames[key] then return end
                    local db = self.db.profile
                    local spacing = db.spacing
                    local h, p, i = db.health, db.power, db.info
                    local totalHeight = (h.enabled and h.height or 0) + (p.enabled and p.height or 0) + (i.enabled and i.height or 0) + spacing * ((h.enabled and p.enabled and i.enabled) and 2 or (h.enabled and p.enabled) and 1 or 0)
                    local width = math.max(h.enabled and h.width or 0, p.enabled and p.width or 0, i.enabled and i.width or 0)

                    local frameType = "Button"
                    local template = "SecureUnitButtonTemplate,BackdropTemplate"
                    local frame = CreateFrame(frameType, "MidnightUI_"..key, UIParent, template)
                    frame:SetSize(width, totalHeight)
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

                function UnitFrames:UpdateUnitFrame(key, unit)
                    local db = self.db.profile
                    local frame = frames[key]
                    if not frame then return end
                    local h, p, i = db.health, db.power, db.info

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
                    frame.healthBar:SetMinMaxValues(0, maxhp)
                    frame.healthBar:SetValue(curhp)
                    frame.healthBar.text:SetFont(LSM:Fetch("font", h.font), h.fontSize, h.fontOutline)
                    frame.healthBar.text:SetTextColor(unpack(h.fontColor or {1,1,1,1}))
                    local hpPct = nil
                    pcall(function() hpPct = (maxhp and maxhp > 0) and math.floor((curhp / maxhp) * 100) or 0 end)
                    local healthStr = string.format("%s / %s (%s%%)", tostring(curhp or 0), tostring(maxhp or 0), tostring(hpPct or 0))
                    frame.healthBar.text:SetText(healthStr)

                    local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit)
                    frame.powerBar:SetMinMaxValues(0, maxpp)
                    frame.powerBar:SetValue(curpp)
                    frame.powerBar.text:SetFont(LSM:Fetch("font", p.font), p.fontSize, p.fontOutline)
                    frame.powerBar.text:SetTextColor(unpack(p.fontColor or {1,1,1,1}))
                    local powerStr = string.format("%s / %s", tostring(curpp or 0), tostring(maxpp or 0))
                    frame.powerBar.text:SetText(powerStr)

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