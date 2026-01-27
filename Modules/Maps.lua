local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local Maps = MidnightUI:NewModule("Maps", "AceEvent-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- -----------------------------------------------------------------------------
-- DATABASE DEFAULTS
-- -----------------------------------------------------------------------------
local defaults = {
    profile = {
        -- Position (Saved)
        position = { point = "TOPRIGHT", x = -25, y = -50 },

        -- Appearance
        shape = "SQUARE", -- SQUARE or ROUND
        size = 190,
        borderSize = 1,
        borderColor = {0, 0, 0, 1},
        locked = false,
        autoZoom = true,
        
        -- Text Elements
        showClock = true,
        showZone = true,
        showCoords = true,
        
        -- Icon Visibility
        showCalendar = true,
        showTracking = true,
        showMail = true,
        showMissions = true,
        showQueue = true,
        
        -- Text Styling
        font = "Friz Quadrata TT",
        fontSize = 12,
        fontOutline = "OUTLINE",
        
        -- Widget Configs
        clock = { point = "BOTTOM", x = 0, y = -2, color = {1, 1, 1, 1} },
        zone = { point = "TOP", x = 0, y = 5, color = {1, 0.8, 0, 1} },
        coords = { point = "BOTTOM", x = 0, y = 12, color = {1, 1, 1, 1} },
    }
}

-- -----------------------------------------------------------------------------
-- INITIALIZATION
-- -----------------------------------------------------------------------------
function Maps:OnInitialize()
    self.db = MidnightUI.db:RegisterNamespace("Maps", defaults)
    
    if not MidnightUI.db.profile.modules.maps then 
        self:Disable()
        return 
    end
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Maps:PLAYER_ENTERING_WORLD()
    self:SetupMinimap()
    self:SetupElements()
    self:SkinBlizzardButtons()
    self:HookScripts()
    
    -- Force Layout Update
    self:UpdateLayout()
end

-- -----------------------------------------------------------------------------
-- CORE MINIMAP SETUP
-- -----------------------------------------------------------------------------
function Maps:SetupMinimap()
    -- Move the entire MinimapCluster
    MinimapCluster:SetMovable(true)
    MinimapCluster:EnableMouse(true)
    MinimapCluster:RegisterForDrag("LeftButton")
    MinimapCluster:SetUserPlaced(true)
    MinimapCluster.ignoreFramePositionManager = true
    
    -- Position it
    MinimapCluster:ClearAllPoints()
    if self.db.profile.position then
        MinimapCluster:SetPoint(
            self.db.profile.position.point,
            UIParent,
            self.db.profile.position.point,
            self.db.profile.position.x,
            self.db.profile.position.y
        )
    else
        MinimapCluster:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -25, -50)
    end
    
    -- Drag scripts
    MinimapCluster:SetScript("OnDragStart", function(self)
        if not Maps.db.profile.locked or (IsControlKeyDown() and IsAltKeyDown()) then
            self:StartMoving()
        end
    end)
    
    MinimapCluster:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Maps:SaveMinimapPosition()
    end)
end

function Maps:SaveMinimapPosition()
    local point, _, _, x, y = MinimapCluster:GetPoint()
    self.db.profile.position = {
        point = point or "TOPRIGHT",
        x = math.floor(x + 0.5),
        y = math.floor(y + 0.5)
    }
end

-- -----------------------------------------------------------------------------
-- CUSTOM ELEMENTS (Clock, Coords, Zone)
-- -----------------------------------------------------------------------------
function Maps:SetupElements()
    local font = LSM:Fetch("font", self.db.profile.font)
    local size = self.db.profile.fontSize
    local flag = self.db.profile.fontOutline

    -- 1. CLOCK
    if not self.clock then
        self.clock = Minimap:CreateFontString(nil, "OVERLAY")
        self.clock:SetFont(font, size, flag)
        
        C_Timer.NewTicker(1, function()
            local h, m = tonumber(date("%H")), tonumber(date("%M"))
            local timeStr = ""
            if GetCVarBool("timeMgrUseMilitaryTime") then
                timeStr = string.format("%02d:%02d", h, m)
            else
                local suffix = (h >= 12) and " PM" or " AM"
                if h > 12 then h = h - 12 elseif h == 0 then h = 12 end
                timeStr = string.format("%d:%02d%s", h, m, suffix)
            end
            self.clock:SetText(timeStr)
        end)
        
        if TimeManagerClockButton then TimeManagerClockButton:Hide() end
    end
    
    -- 2. COORDINATES
    if not self.coords then
        self.coords = Minimap:CreateFontString(nil, "OVERLAY")
        self.coords:SetFont(font, size, flag)
        
        C_Timer.NewTicker(0.2, function()
            local mapID = C_Map.GetBestMapForUnit("player")
            if mapID then
                local pos = C_Map.GetPlayerMapPosition(mapID, "player")
                if pos then
                    self.coords:SetFormattedText("%.1f, %.1f", pos.x * 100, pos.y * 100)
                    return
                end
            end
            self.coords:SetText("")
        end)
    end
    
    -- 3. ZONE TEXT
    if not self.zone then
        self.zone = Minimap:CreateFontString(nil, "OVERLAY")
        self.zone:SetFont(font, size, flag)
        self.zone:SetWidth(self.db.profile.size)
        self.zone:SetWordWrap(false)
        
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateZoneText")
        self:RegisterEvent("ZONE_CHANGED", "UpdateZoneText")
        self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateZoneText")
        self:UpdateZoneText()
        
        if MinimapCluster.ZoneTextButton then MinimapCluster.ZoneTextButton:Hide() end
        if MinimapZoneText then MinimapZoneText:Hide() end
    end
end

function Maps:UpdateZoneText()
    if self.zone then
        self.zone:SetText(GetMinimapZoneText() or "")
        
        local pvpType = C_PvP.GetZonePVPInfo()
        if pvpType == "friendly" then self.zone:SetTextColor(0.1, 1, 0.1)
        elseif pvpType == "hostile" then self.zone:SetTextColor(1, 0.1, 0.1)
        elseif pvpType == "contested" then self.zone:SetTextColor(1, 0.7, 0)
        elseif pvpType == "sanctuary" then self.zone:SetTextColor(0.4, 0.8, 0.9)
        else self.zone:SetTextColor(1, 0.82, 0) end
    end
end

-- -----------------------------------------------------------------------------
-- BUTTON SKINNING & HIDING
-- -----------------------------------------------------------------------------
function Maps:SkinBlizzardButtons()
    if Minimap.ZoomIn then Minimap.ZoomIn:Hide() end
    if Minimap.ZoomOut then Minimap.ZoomOut:Hide() end
    
    if MinimapCompassTexture then MinimapCompassTexture:SetAlpha(0) end
    if MinimapBorder then MinimapBorder:Hide() end
    if MinimapBorderTop then MinimapBorderTop:Hide() end
    if MinimapNorthTag then MinimapNorthTag:Hide() end
    
    -- Skin specific buttons
    local buttons = {
        GameTimeFrame,
        MinimapCluster.Tracking.Button,
        MinimapCluster.IndicatorFrame.MailFrame,
        MinimapCluster.IndicatorFrame.CraftingOrderFrame,
        ExpansionLandingPageMinimapButton,
        QueueStatusMinimapButton
    }

    for _, btn in pairs(buttons) do
        if btn then
            if btn.Border then btn.Border:SetAlpha(0) end
            if btn.Background then btn.Background:SetAlpha(0) end
            btn:SetParent(Minimap)
            btn:SetFrameStrata("MEDIUM")
            btn:SetFrameLevel(20)
        end
    end
end

-- -----------------------------------------------------------------------------
-- LAYOUT UPDATE
-- -----------------------------------------------------------------------------
function Maps:UpdateLayout()
    local db = self.db.profile
    
    -- DO NOT call Minimap:SetSize() - this triggers the Layout error
    -- Instead, only update MinimapCluster position
    MinimapCluster:ClearAllPoints()
    if db.position then
        MinimapCluster:SetPoint(db.position.point, UIParent, db.position.point, db.position.x, db.position.y)
    else
        MinimapCluster:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -25, -50)
    end

    -- SHAPE
    if db.shape == "SQUARE" then
        Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
    else
        Minimap:SetMaskTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    end
    
    -- Update zone text width
    if self.zone then 
        self.zone:SetWidth(db.size) 
    end

    -- TEXT ELEMENTS
    if self.clock then
        self.clock:ClearAllPoints()
        self.clock:SetPoint(db.clock.point, Minimap, db.clock.point, db.clock.x, db.clock.y)
        self.clock:SetShown(db.showClock)
        self.clock:SetTextColor(unpack(db.clock.color))
    end
    
    if self.coords then
        self.coords:ClearAllPoints()
        self.coords:SetPoint(db.coords.point, Minimap, db.coords.point, db.coords.x, db.coords.y)
        self.coords:SetShown(db.showCoords)
        self.coords:SetTextColor(unpack(db.coords.color))
    end
    
    if self.zone then
        self.zone:ClearAllPoints()
        self.zone:SetPoint(db.zone.point, Minimap, db.zone.point, db.zone.x, db.zone.y)
        self.zone:SetShown(db.showZone)
    end
    
    -- BUTTONS
    self:PlaceButton(GameTimeFrame, "TOPRIGHT", -5, -5, db.showCalendar) 
    self:PlaceButton(MinimapCluster.Tracking.Button, "TOPLEFT", 5, -5, db.showTracking)
    self:PlaceButton(MinimapCluster.IndicatorFrame.MailFrame, "TOPRIGHT", -25, -25, db.showMail)
    self:PlaceButton(ExpansionLandingPageMinimapButton, "BOTTOMLEFT", 5, 5, db.showMissions)
    self:PlaceButton(QueueStatusMinimapButton, "BOTTOMRIGHT", -5, 5, db.showQueue)
end

function Maps:PlaceButton(btn, point, x, y, isShown)
    if btn then
        btn:ClearAllPoints()
        btn:SetPoint(point, Minimap, point, x, y)
        btn:SetScale(0.8)
        btn:SetShown(isShown)
    end
end

-- -----------------------------------------------------------------------------
-- SCRIPTS & HOOKS
-- -----------------------------------------------------------------------------
function Maps:HookScripts()
    if self:IsHooked(Minimap, "OnMouseUp") then return end

    local zoomOutFunc = function()
        if self.db.profile.autoZoom then
            C_Timer.After(10, function() Minimap:SetZoom(0) end)
        end
    end
    self:HookScript(Minimap, "OnMouseUp", zoomOutFunc)
end

function Maps:GetOptions()
    return {
        type = "group",
        name = "Maps",
        order = 10,
        get = function(info) return self.db.profile[info[#info]] end,
        set = function(info, value) self.db.profile[info[#info]] = value; self:UpdateLayout() end,
        args = {
            headerShape = { type = "header", name = "Appearance", order = 1 },
            shape = {
                name = "Map Shape",
                type = "select",
                order = 2,
                values = {SQUARE = "Square", ROUND = "Round"},
            },
            size = {
                name = "Map Size",
                desc = "Note: Changing size requires a /reload to take effect",
                type = "range",
                min = 100, max = 400, step = 1,
                order = 3,
            },
            autoZoom = {
                name = "Auto Zoom Out",
                type = "toggle",
                order = 4,
            },
            locked = {
                name = "Lock Position (Disable CTRL+ALT Drag)",
                type = "toggle",
                order = 5,
            },
            
            headerText = { type = "header", name = "Text Overlay", order = 10 },
            showClock = { name = "Show Clock", type = "toggle", order = 11 },
            showZone = { name = "Show Zone Text", type = "toggle", order = 12 },
            showCoords = { name = "Show Coordinates", type = "toggle", order = 13 },
            
            headerIcons = { type = "header", name = "Icons & Buttons", order = 20 },
            showCalendar = { name = "Calendar", type = "toggle", order = 21 },
            showTracking = { name = "Tracking", type = "toggle", order = 22 },
            showMail = { name = "Mail", type = "toggle", order = 23 },
            showMissions = { name = "Missions / Landing Page", type = "toggle", order = 24 },
            showQueue = { name = "LFG / PvP Queue", type = "toggle", order = 25 },
        }
    }
end