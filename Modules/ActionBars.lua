local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local AB = MidnightUI:NewModule("ActionBars", "AceEvent-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- ============================================================================
-- 1. LOCAL VARIABLES & FRAMES
-- ============================================================================

local bars = {}
local buttonCache = {}
local Masque = LibStub("Masque", true)
local masqueGroup

-- Bar Definitions
local BAR_CONFIGS = {
    ["MainMenuBar"] = { name = "Action Bar 1", hasPages = true, buttonCount = 12, default = { point = "BOTTOM", x = 0, y = 50 } },
    ["MultiBarBottomLeft"] = { name = "Action Bar 2", hasPages = false, buttonCount = 12, default = { point = "BOTTOM", x = 0, y = 88 } },
    ["MultiBarBottomRight"] = { name = "Action Bar 3", hasPages = false, buttonCount = 12, default = { point = "BOTTOM", x = 0, y = 126 } },
    ["MultiBarRight"] = { name = "Action Bar 4", hasPages = false, buttonCount = 12, default = { point = "BOTTOM", x = 0, y = 164 } },
    ["MultiBarLeft"] = { name = "Action Bar 5", hasPages = false, buttonCount = 12, default = { point = "BOTTOM", x = 0, y = 202 } },
    ["MultiBar5"] = { name = "Action Bar 6", hasPages = false, buttonCount = 12, default = { point = "BOTTOM", x = 0, y = 240 } },
    ["MultiBar6"] = { name = "Action Bar 7", hasPages = false, buttonCount = 12, default = { point = "BOTTOM", x = 0, y = 278 } },
    ["MultiBar7"] = { name = "Action Bar 8", hasPages = false, buttonCount = 12, default = { point = "BOTTOM", x = 0, y = 316 } },
    ["PetActionBar"] = { name = "Pet Bar", hasPages = false, buttonCount = 10, default = { point = "BOTTOM", x = -250, y = 354 } },
    ["StanceBar"] = { name = "Stance Bar", hasPages = false, buttonCount = 10, default = { point = "BOTTOM", x = 250, y = 354 } },
}

-- Bar Paging Conditions (for Action Bar 1)
local DEFAULT_PAGING = "[possessbar] 16; [overridebar] 18; [shapeshift] 13; [vehicleui] 16; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; 1"

-- ============================================================================
-- 2. DATABASE DEFAULTS
-- ============================================================================

local defaults = {
    profile = {
        hideGryphons = true,
        buttonSize = 36,
        buttonSpacing = 4,
        showHotkeys = true,
        showMacroNames = true,
        showCooldownNumbers = true,
        font = "Friz Quadrata TT",
        fontSize = 12,
        bars = {}
    }
}

-- Initialize bar defaults
for barKey, config in pairs(BAR_CONFIGS) do
    defaults.profile.bars[barKey] = {
        enabled = true,
        scale = 1.0,
        alpha = 1.0,
        fadeAlpha = 0.2,
        fadeInCombat = false,
        fadeOutCombat = false,
        fadeMouseover = false,
        columns = (barKey == "PetActionBar" or barKey == "StanceBar") and 10 or 12,
        buttonSize = 36,
        buttonSpacing = 4,
        point = config.default.point,
        x = config.default.x,
        y = config.default.y,
        showInPetBattle = barKey == "PetActionBar",
        showInVehicle = barKey == "MainMenuBar",
        pagingCondition = (barKey == "MainMenuBar") and DEFAULT_PAGING or nil,
    }
end

-- ============================================================================
-- 3. INITIALIZATION
-- ============================================================================

function AB:OnInitialize()
    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
end

function AB:OnDBReady()
    if not MidnightUI.db.profile.modules.actionbars then return end
    
    self.db = MidnightUI.db:RegisterNamespace("ActionBars", defaults)
    
    if Masque then
        masqueGroup = Masque:Group("Midnight ActionBars")
    end
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PET_BATTLE_OPENING_START")
    self:RegisterEvent("PET_BATTLE_CLOSE")
    self:RegisterEvent("UNIT_ENTERED_VEHICLE")
    self:RegisterEvent("UNIT_EXITED_VEHICLE")
    
    -- ADDED: Register for Move Mode changes
    self:RegisterMessage("MIDNIGHTUI_MOVEMODE_CHANGED", "OnMoveModeChanged")
    
    -- CHANGED: Initialize bars immediately instead of waiting for PLAYER_ENTERING_WORLD
    -- This ensures bars are created even on /reload
    self:HideBlizzardElements()
    self:InitializeAllBars()
    self:UpdateAllBars()
end

function AB:PLAYER_ENTERING_WORLD()
    self:HideBlizzardElements()
    self:InitializeAllBars()
    self:UpdateAllBars()
    
    -- TEMPORARILY DISABLED - Skinning disabled for now
    -- C_Timer.After(0.5, function()
    --     local Skin = MidnightUI:GetModule("Skin", true)
    --     if Skin and Skin.SkinActionBarButtons then
    --         Skin:SkinActionBarButtons()
    --     end
    -- end)
end

-- ADDED: Handle Move Mode changes
function AB:OnMoveModeChanged(event, enabled)
    -- Update all bars to show/hide drag frames and nudge controls
    self:UpdateAllBars()
end

-- ============================================================================
-- 4. HIDE BLIZZARD ELEMENTS
-- ============================================================================

function AB:HideBlizzardElements()
    -- Hide MainActionBar page controls
    if MainActionBar then
        if MainActionBar.ActionBarPageNumber then
            MainActionBar.ActionBarPageNumber:Hide()
            MainActionBar.ActionBarPageNumber:SetAlpha(0)
            
            if MainActionBar.ActionBarPageNumber.UpButton then
                MainActionBar.ActionBarPageNumber.UpButton:Hide()
            end
            if MainActionBar.ActionBarPageNumber.DownButton then
                MainActionBar.ActionBarPageNumber.DownButton:Hide()
            end
        end
    end
    
    -- Hide MainMenuBar art and arrows (old frame, might still exist)
    if MainMenuBar then
        MainMenuBar:Hide()
        MainMenuBar:SetAlpha(0)
        
        if MainMenuBar.ArtFrame then
            MainMenuBar.ArtFrame:Hide()
            MainMenuBar.ArtFrame:SetAlpha(0)
        end
    end
    
    -- Hide the XP/Rep bar if hideGryphons is enabled, otherwise just reposition it
    if StatusTrackingBarManager then
        if self.db.profile.hideGryphons then
            StatusTrackingBarManager:Hide()
            StatusTrackingBarManager:SetAlpha(0)
        else
            -- Just skin it
            MidnightUI:SkinFrame(StatusTrackingBarManager)
        end
    end
end

-- ============================================================================
-- 5. BAR CREATION & MANAGEMENT
-- ============================================================================

function AB:InitializeAllBars()
    for barKey, config in pairs(BAR_CONFIGS) do
        self:CreateBar(barKey, config)
    end
end

function AB:CreateBar(barKey, config)
    if bars[barKey] then return end
    
    -- Create container frame (SecureHandlerStateTemplate for paging support)
    local container = CreateFrame("Frame", "MidnightAB_"..barKey, UIParent, "SecureHandlerStateTemplate")
    container:SetFrameStrata("LOW")
    container:SetMovable(true)
    container:EnableMouse(false)
    container:SetClampedToScreen(true)
    
    -- Store references
    container.barKey = barKey
    container.config = config
    container.buttons = {}
    bars[barKey] = container
    
    -- Get the actual Blizzard bar frame
    local blizzBar = _G[barKey]
    if blizzBar then
        container.blizzBar = blizzBar
        
        -- Special handling for MainMenuBar
        if barKey == "MainMenuBar" then
            -- Unregister from EditModeManager completely
            if EditModeManagerFrame then
                EditModeManagerFrame:UnregisterFrame(blizzBar)
            end
            
            -- Completely detach from Blizzard's management
            blizzBar:SetMovable(true)
            blizzBar:SetUserPlaced(true)
            blizzBar:SetParent(container)
            blizzBar.ignoreFramePositionManager = true
            blizzBar:EnableMouse(false)
            
            -- Stop ALL scripts that could interfere
            blizzBar:SetScript("OnUpdate", nil)
            blizzBar:SetScript("OnShow", nil)
            blizzBar:SetScript("OnHide", nil)
            blizzBar:SetScript("OnEvent", nil)
            
            -- Kill Blizzard's positioning by hooking the functions
            hooksecurefunc(blizzBar, "SetPoint", function(self)
                if not self.midnightLock then
                    self.midnightLock = true
                    self:ClearAllPoints()
                    self:SetPoint("CENTER", container, "CENTER", 0, 0)
                    self.midnightLock = false
                end
            end)
            
            -- Position it in the container
            blizzBar:ClearAllPoints()
            blizzBar:SetPoint("CENTER", container, "CENTER", 0, 0)
            
            -- Make buttons parent to container instead of MainMenuBar
            for i = 1, 12 do
                local btn = _G["ActionButton"..i]
                if btn then
                    btn:SetParent(container)
                end
            end
        else
            -- Normal handling for other bars
            blizzBar:SetParent(container)
            blizzBar:ClearAllPoints()
            blizzBar:SetAllPoints(container)
            
            if blizzBar.SetMovable then blizzBar:SetMovable(true) end
            if blizzBar.SetUserPlaced then blizzBar:SetUserPlaced(true) end
            if blizzBar.ignoreFramePositionManager then
                blizzBar.ignoreFramePositionManager = true
            end
        end
        
        -- Setup bar paging for Action Bar 1
        if barKey == "MainMenuBar" and config.hasPages then
            self:SetupBarPaging(container)
        end
    end
    
    -- Collect buttons (do this even if blizzBar is nil, for MainMenuBar)
    self:CollectButtons(container, barKey)
    
    -- CHANGED: Create drag frame for Move Mode with enhanced styling
    container.dragFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
    container.dragFrame:SetAllPoints()
    container.dragFrame:EnableMouse(false)
    container.dragFrame:SetFrameStrata("DIALOG")
    container.dragFrame:SetFrameLevel(100) -- Ensure it's above buttons
    
    -- Green border and semi-transparent background
    container.dragFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, 
        edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    container.dragFrame:SetBackdropColor(0, 0.5, 0, 0.2)  -- Semi-transparent green
    container.dragFrame:SetBackdropBorderColor(0, 1, 0, 1) -- Bright green border
    container.dragFrame:Hide()
    
    -- CHANGED: Create label with larger, more visible text
    container.label = container.dragFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    container.label:SetPoint("CENTER")
    container.label:SetText(config.name)
    container.label:SetTextColor(1, 1, 1, 1)
    container.label:SetShadowOffset(2, -2)
    container.label:SetShadowColor(0, 0, 0, 1)
    
    -- Drag handlers using Movable module
    local Movable = MidnightUI:GetModule("Movable")
    
    container.dragFrame:RegisterForDrag("LeftButton")
    container.dragFrame:SetScript("OnDragStart", function(self)
        -- Only allow dragging with CTRL+ALT or Move Mode
        if (IsControlKeyDown() and IsAltKeyDown()) or MidnightUI.moveMode then
            container:StartMoving()
        end
    end)
    container.dragFrame:SetScript("OnDragStop", function(self)
        container:StopMovingOrSizing()
        AB:SaveBarPosition(barKey)
    end)
    container.dragFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            MidnightUI:OpenConfig()
        end
    end)
    
    -- Create compact arrow nudge controls for this action bar
    local nudgeFrame = Movable:CreateContainerArrows(
        container.dragFrame,
        { offsetX = 0, offsetY = 0 },
        function()
            -- Reset callback
            local config = BAR_CONFIGS[barKey]
            if config and config.default then
                local db = AB.db.profile.bars[barKey]
                db.point = config.default.point
                db.x = config.default.x
                db.y = config.default.y
                
                container:ClearAllPoints()
                container:SetPoint(db.point, UIParent, db.point, db.x, db.y)
            end
        end
    )
    
    container.nudgeFrame = nudgeFrame
    
    -- Register nudge frame with dragFrame as parent
    if nudgeFrame then
        Movable:RegisterNudgeFrame(nudgeFrame, container.dragFrame)
    end
    
    return container
end

-- ============================================================================
-- 5.5 BAR PAGING SYSTEM
-- ============================================================================

function AB:CollectButtons(container, barKey)
    local buttons = {}
    
    if barKey == "MainMenuBar" then
        for i = 1, 12 do
            local btn = _G["ActionButton"..i]
            if btn then table.insert(buttons, btn) end
        end
    elseif barKey == "PetActionBar" then
        for i = 1, 10 do
            local btn = _G["PetActionButton"..i]
            if btn then table.insert(buttons, btn) end
        end
    elseif barKey == "StanceBar" then
        for i = 1, 10 do
            local btn = _G["StanceButton"..i]
            if btn then table.insert(buttons, btn) end
        end
    else
        -- Standard action bars
        local barName = barKey
        for i = 1, 12 do
            local btn = _G[barName.."Button"..i]
            if btn then table.insert(buttons, btn) end
        end
    end
    
    container.buttons = buttons
    
    -- Cache buttons globally for skinning
    for _, btn in ipairs(buttons) do
        buttonCache[btn] = true
    end
end

function AB:SetupBarPaging(container)
    local db = self.db.profile.bars["MainMenuBar"]
    local pagingCondition = db.pagingCondition or DEFAULT_PAGING
    
    -- Register state driver for bar paging
    RegisterStateDriver(container, "actionpage", pagingCondition)
    
    -- Handle state changes
    container:SetAttribute("_onstate-actionpage", [[
        self:SetAttribute("actionpage", newstate)
        control:ChildUpdate("actionpage", newstate)
    ]])
    
    -- Update buttons when page changes
    container:HookScript("OnAttributeChanged", function(self, name, value)
        if name == "actionpage" and value then
            AB:UpdateMainBarButtons(tonumber(value))
        end
    end)
end

function AB:UpdateMainBarButtons(page)
    if not page then return end
    
    local container = bars["MainMenuBar"]
    if not container then return end
    
    -- Update button actions based on current page
    for i, btn in ipairs(container.buttons) do
        if btn and btn.UpdateAction then
            btn:UpdateAction()
        end
    end
end

function AB:UpdateBarPaging(barKey)
    if barKey ~= "MainMenuBar" then return end
    
    local container = bars[barKey]
    if not container then return end
    
    local db = self.db.profile.bars[barKey]
    local pagingCondition = db.pagingCondition or DEFAULT_PAGING
    
    -- Update the state driver
    RegisterStateDriver(container, "actionpage", pagingCondition)
end

-- ============================================================================
-- 6. BAR LAYOUT & POSITIONING
-- ============================================================================

function AB:UpdateAllBars()
    for barKey, container in pairs(bars) do
        self:UpdateBar(barKey)
    end
end

function AB:UpdateBar(barKey)
    local container = bars[barKey]
    if not container then return end
    
    local db = self.db.profile.bars[barKey]
    if not db then return end
    
    -- Show/Hide based on settings
    if db.enabled then
        container:Show()
    else
        container:Hide()
        -- Also hide all hotkey frames on buttons when bar is disabled
        for _, btn in ipairs(container.buttons) do
            if btn then
                local hotkey = btn.HotKey or _G[btn:GetName().."HotKey"]
                if hotkey then
                    hotkey:Hide()
                end
            end
        end
        return
    end
    
    -- Apply scale and alpha
    container:SetScale(db.scale)
    container:SetAlpha(db.alpha)
    
    -- Update position
    container:ClearAllPoints()
    container:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    
    -- Layout buttons
    self:LayoutButtons(container, barKey)
    
    -- Update fading
    self:UpdateBarFading(barKey)
    
    -- Handle Move Mode display
    if MidnightUI.moveMode then
        -- Show drag frame with green border
        if container.dragFrame then
            container.dragFrame:Show()
            container.dragFrame:EnableMouse(true)
        end
        
        -- Fade the actual action buttons to 30% opacity
        for _, btn in ipairs(container.buttons) do
            if btn then
                btn:SetAlpha(0.3)
            end
        end
        
        -- Show arrow nudge controls (they show automatically with parent drag frame)
        if container.nudgeFrame then
            -- Arrow buttons are already parented to dragFrame and will show when it shows
            -- Just make sure they're visible
            if container.nudgeFrame.UP then container.nudgeFrame.UP:Show() end
            if container.nudgeFrame.DOWN then container.nudgeFrame.DOWN:Show() end
            if container.nudgeFrame.LEFT then container.nudgeFrame.LEFT:Show() end
            if container.nudgeFrame.RIGHT then container.nudgeFrame.RIGHT:Show() end
            if container.nudgeFrame.RESET then container.nudgeFrame.RESET:Show() end
        end
    else
        -- Hide drag frame
        if container.dragFrame then
            container.dragFrame:Hide()
            container.dragFrame:EnableMouse(false)
        end
        
        -- Restore button opacity to 100%
        for _, btn in ipairs(container.buttons) do
            if btn then
                btn:SetAlpha(1.0)
            end
        end
        
        -- Hide arrow nudge controls
        if container.nudgeFrame then
            if container.nudgeFrame.UP then container.nudgeFrame.UP:Hide() end
            if container.nudgeFrame.DOWN then container.nudgeFrame.DOWN:Hide() end
            if container.nudgeFrame.LEFT then container.nudgeFrame.LEFT:Hide() end
            if container.nudgeFrame.RIGHT then container.nudgeFrame.RIGHT:Hide() end
            if container.nudgeFrame.RESET then container.nudgeFrame.RESET:Hide() end
        end
    end
    
    -- Special handling for MainMenuBar
    if barKey == "MainMenuBar" and container.blizzBar then
        container.blizzBar:Show()
    end
end

function AB:LayoutButtons(container, barKey)
    local db = self.db.profile.bars[barKey]
    local buttons = container.buttons
    
    if #buttons == 0 then return end
    
    local buttonSize = db.buttonSize
    local spacing = db.buttonSpacing
    local columns = db.columns
    
    -- Calculate container size
    local rows = math.ceil(#buttons / columns)
    local width = (buttonSize * columns) + (spacing * (columns - 1))
    local height = (buttonSize * rows) + (spacing * (rows - 1))
    
    container:SetSize(width, height)
    
    -- Position buttons
    for i, btn in ipairs(buttons) do
        btn:ClearAllPoints()
        btn:SetParent(container)
        btn:SetSize(buttonSize, buttonSize)
        
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)
        
        local xOffset = col * (buttonSize + spacing)
        local yOffset = -row * (buttonSize + spacing)
        
        btn:SetPoint("TOPLEFT", container, "TOPLEFT", xOffset, yOffset)
        
        -- Update button elements
        self:UpdateButtonElements(btn)
    end
end

function AB:UpdateButtonElements(btn)
    local db = self.db.profile
    
    -- Completely hide TextOverlayContainer - we'll create our own keybind display
    if btn.TextOverlayContainer then
        btn.TextOverlayContainer:Hide()
        btn.TextOverlayContainer:SetAlpha(0)
    end
    
    -- Create our own custom hotkey fontstring if it doesn't exist
    if not btn.customHotkey then
        btn.customHotkey = btn:CreateFontString(nil, "OVERLAY")
        btn.customHotkey:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
        btn.customHotkey:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        btn.customHotkey:SetTextColor(1, 1, 1)
        btn.customHotkey:SetJustifyH("RIGHT")
    end
    
    -- Update custom hotkey text from the button's action binding
    -- Check if button, its parent container, and the original Blizzard bar are all visible
    local parentBar = btn.bar or btn:GetParent()
    local shouldShow = db.showHotkeys and btn:IsVisible()
    
    -- Additional check: if this is a StanceBar or PetActionBar, check if Blizzard is showing the bar
    if shouldShow and parentBar then
        local parentName = parentBar:GetName()
        if parentName == "StanceBar" or parentName == "PetActionBar" then
            -- These bars are hidden by Blizzard for classes without stances/pets
            shouldShow = parentBar:IsVisible() and parentBar:IsShown()
        end
    end
    
    if shouldShow then
        local key = GetBindingKey(btn.commandName or btn.bindingAction)
        if key then
            local text = GetBindingText(key, "KEY_", 1)
            text = string.upper(text)
            
            -- Abbreviate common patterns
            text = text:gsub("MOUSEWHEELUP", "MWU")
            text = text:gsub("MOUSEWHEELDOWN", "MWD")
            text = text:gsub("CTRL%-", "C")
            text = text:gsub("SHIFT%-", "S")
            text = text:gsub("ALT%-", "A")
            text = text:gsub("BUTTON", "M")
            
            text = string.sub(text, 1, 4) -- Limit to 4 characters
            btn.customHotkey:SetText(text)
            btn.customHotkey:Show()
        else
            btn.customHotkey:Hide()
        end
    else
        btn.customHotkey:Hide()
    end
    
    -- Ensure icon matches button size exactly
    if btn.icon then
        btn.icon:ClearAllPoints()
        btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    end
    
    -- Fix highlight to match button perfectly
    local highlight = btn:GetHighlightTexture()
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetAllPoints(btn)
        highlight:SetDrawLayer("HIGHLIGHT")
        highlight:SetBlendMode("ADD")
    end
    
    -- Fix pushed texture to match button size
    local pushed = btn:GetPushedTexture()
    if pushed then
        pushed:ClearAllPoints()
        pushed:SetAllPoints(btn)
    end
    
    -- Fix flash texture to match button size
    if btn.Flash then
        btn.Flash:ClearAllPoints()
        btn.Flash:SetAllPoints(btn)
    end
    
    -- Fix checked texture to match button size
    local checked = btn:GetCheckedTexture()
    if checked then
        checked:ClearAllPoints()
        checked:SetAllPoints(btn)
    end
    
    -- Hide NormalTexture (the default button border/background)
    local normalTex = btn:GetNormalTexture()
    if normalTex then
        normalTex:SetAlpha(0)
    end
    
    -- Hide border textures that might show as rectangles
    if btn.Border then
        btn.Border:SetAlpha(0)
    end
    if btn.SlotBackground then
        btn.SlotBackground:SetAlpha(0)
    end
    
    -- Macro name
    local name = btn.Name or _G[btn:GetName().."Name"]
    if name then
        if db.showMacroNames then
            name:Show()
            name:ClearAllPoints()
            name:SetPoint("BOTTOM", 0, 2)
        else
            name:Hide()
        end
    end
    
    -- Cooldown numbers (handled by Cooldowns module, but we can hide the frame)
    local cooldown = btn.cooldown or btn.Cooldown
    if cooldown and not db.showCooldownNumbers then
        if cooldown.SetHideCountdownNumbers then
            cooldown:SetHideCountdownNumbers(true)
        end
    end
end

function AB:SaveBarPosition(barKey)
    local container = bars[barKey]
    if not container then return end
    
    local point, _, _, x, y = container:GetPoint()
    local db = self.db.profile.bars[barKey]
    
    db.point = point
    db.x = math.floor(x + 0.5)
    db.y = math.floor(y + 0.5)
end

-- ============================================================================
-- 7. FADING SYSTEM
-- ============================================================================

function AB:UpdateBarFading(barKey)
    local container = bars[barKey]
    local db = self.db.profile.bars[barKey]
    
    if not container or not db then return end
    
    -- Remove existing fading scripts
    container:SetScript("OnEnter", nil)
    container:SetScript("OnLeave", nil)
    container:SetScript("OnUpdate", nil)
    
    if db.fadeMouseover then
        container:EnableMouse(true)
        container:SetAlpha(db.fadeAlpha)
        
        container:SetScript("OnEnter", function()
            UIFrameFadeIn(container, 0.2, container:GetAlpha(), db.alpha)
        end)
        
        container:SetScript("OnLeave", function()
            UIFrameFadeOut(container, 0.2, container:GetAlpha(), db.fadeAlpha)
        end)
    elseif db.fadeInCombat or db.fadeOutCombat then
        container:SetScript("OnUpdate", function(self)
            local inCombat = InCombatLockdown()
            local targetAlpha = db.alpha
            
            if db.fadeInCombat and inCombat then
                targetAlpha = db.alpha
            elseif db.fadeOutCombat and not inCombat then
                targetAlpha = db.fadeAlpha
            end
            
            if self:GetAlpha() ~= targetAlpha then
                UIFrameFadeIn(self, 0.3, self:GetAlpha(), targetAlpha)
            end
        end)
    else
        container:EnableMouse(false)
        container:SetAlpha(db.alpha)
    end
end

-- ============================================================================
-- 9. EVENT HANDLERS
-- ============================================================================

function AB:PLAYER_REGEN_ENABLED()
    self:UpdateAllBars()
end

function AB:PLAYER_REGEN_DISABLED()
    self:UpdateAllBars()
end

function AB:PET_BATTLE_OPENING_START()
    for barKey, container in pairs(bars) do
        local db = self.db.profile.bars[barKey]
        if not db.showInPetBattle then
            container:Hide()
        end
    end
end

function AB:PET_BATTLE_CLOSE()
    self:UpdateAllBars()
end

function AB:UNIT_ENTERED_VEHICLE(event, unit)
    if unit == "player" then
        for barKey, container in pairs(bars) do
            local db = self.db.profile.bars[barKey]
            if not db.showInVehicle then
                container:Hide()
            end
        end
    end
end

function AB:UNIT_EXITED_VEHICLE(event, unit)
    if unit == "player" then
        self:UpdateAllBars()
    end
end

-- ============================================================================
-- 10. OPTIONS
-- ============================================================================

function AB:GetOptions()
    if not self.db then
        self.db = MidnightUI.db:RegisterNamespace("ActionBars", defaults)
    end
    
    local options = {
        type = "group",
        name = "Action Bars",
        childGroups = "tab",
        args = {
            general = {
                name = "General",
                type = "group",
                order = 1,
                args = {
                    -- Note: Button skinning is controlled by the Skins module
                    hideGryphons = {
                        name = "Hide Gryphons",
                        desc = "Hide main bar gryphons and art",
                        type = "toggle",
                        order = 3,
                        get = function() return self.db.profile.hideGryphons end,
                        set = function(_, v)
                            self.db.profile.hideGryphons = v
                            self:HideBlizzardElements()
                        end
                    },
                    spacer0 = { name = "", type = "header", order = 5 },
                    moveNote = {
                        name = "|cffaaaaaa(Use /muimove or click M button to enable Move Mode)\nThen hover over bars to see nudge controls|r",
                        type = "description",
                        order = 5.5,
                        fontSize = "medium",
                    },
                    resetAllPositions = {
                        name = "Reset All Bar Positions",
                        desc = "Reset all action bars to their default positions",
                        type = "execute",
                        order = 6,
                        confirm = true,
                        confirmText = "Are you sure you want to reset all bar positions to default?",
                        func = function()
                            for barKey, config in pairs(BAR_CONFIGS) do
                                local db = self.db.profile.bars[barKey]
                                db.point = config.default.point
                                db.x = config.default.x
                                db.y = config.default.y
                                self:UpdateBar(barKey)
                            end
                            print("|cff00ff00MidnightUI:|r All action bar positions have been reset to default.")
                        end
                    },
                    spacer1 = { name = "", type = "description", order = 10 },
                    buttonSize = {
                        name = "Global Button Size",
                        desc = "Default button size for all bars",
                        type = "range",
                        order = 11,
                        min = 20,
                        max = 64,
                        step = 1,
                        get = function() return self.db.profile.buttonSize end,
                        set = function(_, v)
                            self.db.profile.buttonSize = v
                            for barKey in pairs(BAR_CONFIGS) do
                                self.db.profile.bars[barKey].buttonSize = v
                            end
                            self:UpdateAllBars()
                        end
                    },
                    buttonSpacing = {
                        name = "Global Button Spacing",
                        desc = "Default spacing between buttons",
                        type = "range",
                        order = 12,
                        min = 0,
                        max = 20,
                        step = 1,
                        get = function() return self.db.profile.buttonSpacing end,
                        set = function(_, v)
                            self.db.profile.buttonSpacing = v
                            for barKey in pairs(BAR_CONFIGS) do
                                self.db.profile.bars[barKey].buttonSpacing = v
                            end
                            self:UpdateAllBars()
                        end
                    },
                    spacer2 = { name = "", type = "description", order = 20 },
                    showHotkeys = {
                        name = "Show Hotkeys",
                        desc = "Display keybind text on buttons",
                        type = "toggle",
                        order = 21,
                        get = function() return self.db.profile.showHotkeys end,
                        set = function(_, v)
                            self.db.profile.showHotkeys = v
                            self:UpdateAllBars()
                        end
                    },
                    showMacroNames = {
                        name = "Show Macro Names",
                        desc = "Display macro names on buttons",
                        type = "toggle",
                        order = 22,
                        get = function() return self.db.profile.showMacroNames end,
                        set = function(_, v)
                            self.db.profile.showMacroNames = v
                            self:UpdateAllBars()
                        end
                    },
                    showCooldownNumbers = {
                        name = "Show Cooldown Numbers",
                        desc = "Display cooldown countdown numbers",
                        type = "toggle",
                        order = 23,
                        get = function() return self.db.profile.showCooldownNumbers end,
                        set = function(_, v)
                            self.db.profile.showCooldownNumbers = v
                            self:UpdateAllBars()
                        end
                    },
                }
            },
            bars = {
                name = "Bars",
                type = "group",
                order = 2,
                args = {}
            }
        }
    }

    -- Define the desired order for bars
    local barDisplayOrder = {
        "MainMenuBar",
        "MultiBarBottomLeft",
        "MultiBarBottomRight",
        "MultiBarRight",
        "MultiBarLeft",
        "MultiBar5",
        "MultiBar6",
        "MultiBar7",
        "PetActionBar",
        "StanceBar"
    }

    -- Add individual bar options in the specified order
    for barOrder, barKey in ipairs(barDisplayOrder) do
        local config = BAR_CONFIGS[barKey]
        if config then
            local barOptions = {
                name = config.name,
                type = "group",
                order = barOrder,
                args = {
                    enabled = {
                        name = "Enable",
                        desc = "Show this action bar",
                        type = "toggle",
                        order = 1,
                        get = function() return self.db.profile.bars[barKey].enabled end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].enabled = v
                            self:UpdateBar(barKey)
                        end
                    },
                    scale = {
                        name = "Scale",
                        desc = "Scale of the entire bar",
                        type = "range",
                        order = 2,
                        min = 0.5,
                        max = 2.0,
                        step = 0.05,
                        get = function() return self.db.profile.bars[barKey].scale end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].scale = v
                            self:UpdateBar(barKey)
                        end
                    },
                    alpha = {
                        name = "Opacity",
                        desc = "Normal opacity of the bar",
                        type = "range",
                        order = 3,
                        min = 0,
                        max = 1,
                        step = 0.05,
                        get = function() return self.db.profile.bars[barKey].alpha end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].alpha = v
                            self:UpdateBar(barKey)
                        end
                    },
                    columns = {
                        name = "Columns",
                        desc = "Number of buttons per row",
                        type = "range",
                        order = 4,
                        min = 1,
                        max = config.buttonCount,
                        step = 1,
                        get = function() return self.db.profile.bars[barKey].columns end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].columns = v
                            self:UpdateBar(barKey)
                        end
                    },
                    buttonSize = {
                        name = "Button Size",
                        desc = "Size of buttons in this bar",
                        type = "range",
                        order = 5,
                        min = 20,
                        max = 64,
                        step = 1,
                        get = function() return self.db.profile.bars[barKey].buttonSize end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].buttonSize = v
                            self:UpdateBar(barKey)
                        end
                    },
                    buttonSpacing = {
                        name = "Button Spacing",
                        desc = "Space between buttons",
                        type = "range",
                        order = 6,
                        min = 0,
                        max = 20,
                        step = 1,
                        get = function() return self.db.profile.bars[barKey].buttonSpacing end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].buttonSpacing = v
                            self:UpdateBar(barKey)
                        end
                    },
                    spacer1 = { name = "", type = "header", order = 10 },
                    fadeMouseover = {
                        name = "Fade on Mouseover",
                        desc = "Fade bar until you mouse over it",
                        type = "toggle",
                        order = 11,
                        get = function() return self.db.profile.bars[barKey].fadeMouseover end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].fadeMouseover = v
                            if v then
                                self.db.profile.bars[barKey].fadeInCombat = false
                                self.db.profile.bars[barKey].fadeOutCombat = false
                            end
                            self:UpdateBar(barKey)
                        end
                    },
                    fadeInCombat = {
                        name = "Fade In Combat",
                        desc = "Show bar fully in combat",
                        type = "toggle",
                        order = 12,
                        disabled = function() return self.db.profile.bars[barKey].fadeMouseover end,
                        get = function() return self.db.profile.bars[barKey].fadeInCombat end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].fadeInCombat = v
                            self:UpdateBar(barKey)
                        end
                    },
                    fadeOutCombat = {
                        name = "Fade Out of Combat",
                        desc = "Fade bar when out of combat",
                        type = "toggle",
                        order = 13,
                        disabled = function() return self.db.profile.bars[barKey].fadeMouseover end,
                        get = function() return self.db.profile.bars[barKey].fadeOutCombat end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].fadeOutCombat = v
                            self:UpdateBar(barKey)
                        end
                    },
                    fadeAlpha = {
                        name = "Faded Opacity",
                        desc = "Opacity when faded",
                        type = "range",
                        order = 14,
                        min = 0,
                        max = 1,
                        step = 0.05,
                        get = function() return self.db.profile.bars[barKey].fadeAlpha end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].fadeAlpha = v
                            self:UpdateBar(barKey)
                        end
                    },
                    spacer2 = { name = "", type = "header", order = 20 },
                    showInPetBattle = {
                        name = "Show in Pet Battles",
                        desc = "Keep bar visible during pet battles",
                        type = "toggle",
                        order = 21,
                        get = function() return self.db.profile.bars[barKey].showInPetBattle end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].showInPetBattle = v
                        end
                    },
                    showInVehicle = {
                        name = "Show in Vehicles",
                        desc = "Keep bar visible when in a vehicle",
                        type = "toggle",
                        order = 22,
                        get = function() return self.db.profile.bars[barKey].showInVehicle end,
                        set = function(_, v)
                            self.db.profile.bars[barKey].showInVehicle = v
                        end
                    },
                    spacer3 = { name = "", type = "header", order = 30 },
                    resetPosition = {
                        name = "Reset Position",
                        desc = "Reset bar to default position",
                        type = "execute",
                        order = 31,
                        func = function()
                            local db = self.db.profile.bars[barKey]
                            db.point = config.default.point
                            db.x = config.default.x
                            db.y = config.default.y
                            self:UpdateBar(barKey)
                        end
                    }
                }
            }
            
            -- Add paging options for Action Bar 1
            if barKey == "MainMenuBar" and config.hasPages then
                barOptions.args.spacer4 = { name = "", type = "header", order = 40 }
                barOptions.args.pagingHeader = {
                    name = "Bar Paging",
                    type = "description",
                    order = 41,
                    fontSize = "medium",
                }
                barOptions.args.pagingCondition = {
                    name = "Paging Condition",
                    desc = "Macro condition that controls which bar page is shown. Advanced users only.",
                    type = "input",
                    width = "full",
                    multiline = 3,
                    order = 42,
                    get = function() return self.db.profile.bars[barKey].pagingCondition or DEFAULT_PAGING end,
                    set = function(_, v)
                        self.db.profile.bars[barKey].pagingCondition = v
                        self:UpdateBarPaging(barKey)
                    end
                }
                barOptions.args.resetPaging = {
                    name = "Reset to Default",
                    desc = "Reset paging condition to default",
                    type = "execute",
                    order = 43,
                    func = function()
                        self.db.profile.bars[barKey].pagingCondition = DEFAULT_PAGING
                        self:UpdateBarPaging(barKey)
                    end
                }
                barOptions.args.pagingHelp = {
                    name = "Default condition handles: Possess bar, Override bar, Shapeshift forms, Vehicles, and manual bar switching (via keybinds).",
                    type = "description",
                    order = 44,
                    fontSize = "small",
                }
            end
            
            options.args.bars.args[barKey] = barOptions
        end
    end
    
    return options
end