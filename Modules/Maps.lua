local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local Maps = MidnightUI:NewModule("Maps", "AceEvent-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- -----------------------------------------------------------------------------
-- DATABASE DEFAULTS
-- -----------------------------------------------------------------------------
local defaults = {
    profile = {
        -- Appearance
        shape = "SQUARE", -- SQUARE or ROUND
        autoZoom = true,
        
        -- Manual positioning offset (relative to MinimapCluster)
        offsetX = 0,
        offsetY = 0,
        
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
    -- CRITICAL FIX: Stub out Layout function to prevent errors
    if not Minimap.Layout or Minimap.Layout == nil then
        Minimap.Layout = function() end
    end
    
    self:SetupMinimapPosition()
    self:SetupMinimapDragging()
    self:SetupElements()
    self:SkinBlizzardButtons()
    self:UpdateLayout()
end

-- -----------------------------------------------------------------------------
-- MINIMAP POSITIONING
-- -----------------------------------------------------------------------------
function Maps:SetupMinimapPosition()
    -- Store original SetPoint function
    if not self.origSetPoint then
        self.origSetPoint = Minimap.SetPoint
    end
    
    -- Override SetPoint to add our offsets
    Minimap.SetPoint = function(frame, ...)
        local point, relativeTo, relativePoint, x, y = ...
        
        -- If called by Blizzard with default positioning, add our offsets
        if x and y then
            local db = Maps.db.profile
            Maps.origSetPoint(frame, point, relativeTo, relativePoint, x + db.offsetX, y + db.offsetY)
        else
            Maps.origSetPoint(frame, ...)
        end
    end
    
    -- Apply offsets immediately
    self:ApplyMinimapOffset()
end

function Maps:ApplyMinimapOffset()
    local db = self.db.profile
    
    -- Clear and reapply position with offsets
    Minimap:ClearAllPoints()
    
    -- Apply offset to Minimap relative to MinimapCluster
    self.origSetPoint(Minimap, "CENTER", MinimapCluster, "CENTER", db.offsetX, db.offsetY)
end

-- -----------------------------------------------------------------------------
-- MINIMAP DRAGGING (CTRL+ALT ONLY)
-- -----------------------------------------------------------------------------
function Maps:SetupMinimapDragging()
    -- Make Minimap movable
    Minimap:SetMovable(true)
    Minimap:EnableMouse(true)
    Minimap:RegisterForDrag("LeftButton")
    
    -- Store the starting positions
    local dragStartOffsetX, dragStartOffsetY
    local dragStartMinimapX, dragStartMinimapY
    local isDragging = false
    
    Minimap:SetScript("OnDragStart", function(self)
        -- Only allow dragging with CTRL+ALT
        if IsControlKeyDown() and IsAltKeyDown() then
            isDragging = true
            
            -- Store the current offset
            dragStartOffsetX = Maps.db.profile.offsetX
            dragStartOffsetY = Maps.db.profile.offsetY
            
            -- Store the minimap's starting center position
            dragStartMinimapX, dragStartMinimapY = self:GetCenter()
            
            self:StartMoving()
        end
    end)
    
    Minimap:SetScript("OnDragStop", function(self)
        if not isDragging then return end
        
        self:StopMovingOrSizing()
        isDragging = false
        
        -- Get the new position after dragging
        local newMinimapX, newMinimapY = self:GetCenter()
        
        if dragStartMinimapX and dragStartMinimapY and newMinimapX and newMinimapY then
            -- Calculate how far the minimap moved
            local deltaX = newMinimapX - dragStartMinimapX
            local deltaY = newMinimapY - dragStartMinimapY
            
            -- Add the movement delta to the original offset
            local newOffsetX = dragStartOffsetX + deltaX
            local newOffsetY = dragStartOffsetY + deltaY
            
            -- Update database with rounded values
            Maps.db.profile.offsetX = math.floor(newOffsetX + 0.5)
            Maps.db.profile.offsetY = math.floor(newOffsetY + 0.5)
            
            -- Reapply position using the new offset
            Maps:ApplyMinimapOffset()
        end
    end)
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
        self.zone:SetWidth(200)
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

    -- ONLY SET SHAPE ONCE - Never call SetMaskTexture again after this
    if not self.shapeInitialized then
        if db.shape == "SQUARE" then
            Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
        else
            Minimap:SetMaskTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        end
        self.shapeInitialized = true
    end
    
    -- Apply position offset
    self:ApplyMinimapOffset()

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

function Maps:GetOptions()
    return {
        type = "group",
        name = "Maps",
        order = 10,
        get = function(info) return self.db.profile[info[#info]] end,
        set = function(info, value) 
            self.db.profile[info[#info]] = value
            if info[#info] == "shape" then
                -- Changing shape requires a reload
                ReloadUI()
            else
                self:UpdateLayout()
            end
        end,
        args = {
            headerShape = { type = "header", name = "Appearance", order = 1 },
            shape = {
                name = "Map Shape (Requires /reload)",
                type = "select",
                order = 2,
                values = {SQUARE = "Square", ROUND = "Round"},
            },
            autoZoom = {
                name = "Auto Zoom Out",
                type = "toggle",
                order = 4,
            },
            positionNote = {
                name = "|cffaaaaaa(Use Blizzard Edit Mode to move MinimapCluster, then hold CTRL+ALT and drag the minimap to fine-tune position)|r",
                type = "description",
                order = 5,
                fontSize = "medium",
            },
            
            headerPosition = { type = "header", name = "Position Fine-Tuning", order = 6 },
            offsetX = {
                name = "Horizontal Offset",
                desc = "Manual horizontal offset (or drag minimap with CTRL+ALT)",
                type = "range",
                order = 7,
                min = -200,
                max = 200,
                step = 1,
            },
            offsetY = {
                name = "Vertical Offset",
                desc = "Manual vertical offset (or drag minimap with CTRL+ALT)",
                type = "range",
                order = 8,
                min = -200,
                max = 200,
                step = 1,
            },
            resetOffsets = {
                name = "Reset Offsets",
                desc = "Reset position offsets to 0",
                type = "execute",
                order = 9,
                func = function()
                    self.db.profile.offsetX = 0
                    self.db.profile.offsetY = 0
                    self:UpdateLayout()
                end
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