local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local Movable = MidnightUI:NewModule("Movable", "AceEvent-3.0")

-- ============================================================================
-- MOVABLE FRAME SYSTEM
-- Centralized drag and nudge functionality for all MidnightUI modules
-- ============================================================================

-- Store registered movable frames with their highlight overlays
Movable.registeredFrames = {}
Movable.registeredNudgeFrames = {}

-- ============================================================================
-- 1. DRAG FUNCTIONALITY
-- ============================================================================

--[[
    Makes a frame draggable with CTRL+ALT or Move Mode
    Also adds green highlight in Move Mode
    @param frame - The frame to make draggable
    @param saveCallback - Optional function(point, x, y) called when drag stops
    @param unlockCheck - Optional function() that returns true if frame should be movable
]]
function Movable:MakeFrameDraggable(frame, saveCallback, unlockCheck)
    if not frame then return end
    
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    
    local isDragging = false
    
    frame:SetScript("OnDragStart", function(self)
        -- Check if unlocked (if unlockCheck provided) OR CTRL+ALT held OR Move Mode active
        local canMove = true
        if unlockCheck then
            canMove = unlockCheck() or (IsControlKeyDown() and IsAltKeyDown()) or MidnightUI.moveMode
        else
            canMove = (IsControlKeyDown() and IsAltKeyDown()) or MidnightUI.moveMode
        end
        
        if canMove then
            isDragging = true
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        if not isDragging then return end
        
        self:StopMovingOrSizing()
        isDragging = false
        
        -- Save position if callback provided
        if saveCallback then
            local point, _, _, x, y = self:GetPoint()
            saveCallback(point, math.floor(x + 0.5), math.floor(y + 0.5))
        end
    end)
    
    -- Right-click to open config
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            MidnightUI:OpenConfig()
        end
    end)
    
    -- Create green highlight overlay (hidden by default)
    if not frame.movableHighlight then
        frame.movableHighlight = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        frame.movableHighlight:SetAllPoints()
        frame.movableHighlight:SetColorTexture(0, 1, 0, 0.2)
        frame.movableHighlight:Hide()
    end
    
    -- Register this frame for Move Mode highlighting
    table.insert(self.registeredFrames, frame)
end

-- ============================================================================
-- 2. NUDGE CONTROLS (Arrow Buttons)
-- ============================================================================

--[[
    Creates a nudge control frame with arrow buttons
    @param parentFrame - The frame to attach nudge controls to
    @param db - Database table containing offsetX and offsetY
    @param applyCallback - Function() called when offset changes
    @param updateCallback - Optional function() called after nudge display updates
    @param titleText - Optional string to use as the title (defaults to "Move Frame")
    @return nudgeFrame - The created control frame
]]
function Movable:CreateNudgeControls(parentFrame, db, applyCallback, updateCallback, titleText)
    if not parentFrame or not db or not applyCallback then return end
    
    -- Create main nudge frame
    local nudge = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    nudge:SetSize(140, 140)
    nudge:SetFrameStrata("DIALOG")
    nudge:SetFrameLevel(1000)
    nudge:EnableMouse(true)
    nudge:SetMovable(true)
    nudge:RegisterForDrag("LeftButton")
    nudge:SetClampedToScreen(true)
    nudge:Hide()
    
    nudge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    nudge:SetBackdropColor(0, 0, 0, 0.5)
    nudge:SetBackdropBorderColor(0, 1, 0, 1)
    
    -- Make the nudge frame itself draggable
    nudge:SetScript("OnDragStart", function(self) self:StartMoving() end)
    nudge:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Title
    local title = nudge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -12)
    title:SetText(titleText or "Move Frame")
    title:SetTextColor(0, 1, 0)
    nudge.title = title
    
    -- Current offset display
    local offsetText = nudge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    offsetText:SetPoint("CENTER", 0, 0)
    offsetText:SetTextColor(1, 1, 1)
    nudge.offsetText = offsetText
    
    -- Create arrow buttons
    local function CreateArrow(direction, point, x, y)
        local btn = CreateFrame("Button", nil, nudge, "BackdropTemplate")
        btn:SetSize(24, 24)
        btn:SetPoint(point, nudge, point, x, y)
        
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        btn:SetBackdropBorderColor(0, 1, 0, 1)
        
        -- Arrow text using simple ASCII characters
        local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        arrow:SetPoint("CENTER")
        
        if direction == "UP" then arrow:SetText("^")
        elseif direction == "DOWN" then arrow:SetText("v")
        elseif direction == "LEFT" then arrow:SetText("<")
        elseif direction == "RIGHT" then arrow:SetText(">")
        end
        
        arrow:SetTextColor(0, 1, 0, 1)
        
        -- Button hover
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.3, 0.3, 0.3, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Nudge "..direction)
            GameTooltip:AddLine("|cffaaaaaa(Hold Shift for 10px)|r", 1, 1, 1)
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            GameTooltip:Hide()
        end)
        
        -- Click handler
        btn:SetScript("OnClick", function()
            local step = IsShiftKeyDown() and 10 or 1
            
            if direction == "UP" then
                db.offsetY = (db.offsetY or 0) + step
            elseif direction == "DOWN" then
                db.offsetY = (db.offsetY or 0) - step
            elseif direction == "LEFT" then
                db.offsetX = (db.offsetX or 0) - step
            elseif direction == "RIGHT" then
                db.offsetX = (db.offsetX or 0) + step
            end
            
            applyCallback()
            Movable:UpdateNudgeDisplay(nudge, db)
            if updateCallback then updateCallback() end
        end)
    end
    
    -- Create 4 arrow buttons
    CreateArrow("UP", "TOP", 0, 10)
    CreateArrow("DOWN", "BOTTOM", 0, -10)
    CreateArrow("LEFT", "LEFT", -10, 0)
    CreateArrow("RIGHT", "RIGHT", 10, 0)
    
    -- Reset button
    local reset = CreateFrame("Button", nil, nudge, "BackdropTemplate")
    reset:SetSize(50, 20)
    reset:SetPoint("BOTTOM", 0, 15)
    reset:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    reset:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    reset:SetBackdropBorderColor(1, 0, 0, 1)
    
    local resetText = reset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetText:SetPoint("CENTER")
    resetText:SetText("Reset")
    resetText:SetTextColor(1, 0, 0)
    
    reset:SetScript("OnClick", function()
        db.offsetX = 0
        db.offsetY = 0
        applyCallback()
        Movable:UpdateNudgeDisplay(nudge, db)
        if updateCallback then updateCallback() end
    end)
    
    reset:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.2, 0.2, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Reset to Center")
        GameTooltip:Show()
    end)
    
    reset:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        GameTooltip:Hide()
    end)
    
    -- Store reference to parent and callbacks
    nudge.parentFrame = parentFrame
    nudge.db = db
    nudge.applyCallback = applyCallback
    
    -- Initial display update
    self:UpdateNudgeDisplay(nudge, db)
    
    -- Setup mouseover behavior for parent frame
    if parentFrame and not parentFrame.movableNudgeHooked then
        parentFrame:HookScript("OnEnter", function()
            if MidnightUI.moveMode and nudge then
                -- Cancel any pending hide timer
                if nudge.hideTimer then
                    nudge.hideTimer:Cancel()
                    nudge.hideTimer = nil
                end
                Movable:ShowNudgeControls(nudge, parentFrame)
            end
        end)
        
        parentFrame:HookScript("OnLeave", function()
            if nudge then
                -- Delay hiding to allow mouse to move to nudge buttons
                nudge.hideTimer = C_Timer.NewTimer(0.3, function()
                    if nudge and not MouseIsOver(parentFrame) and not MouseIsOver(nudge) then
                        nudge:Hide()
                    end
                    nudge.hideTimer = nil
                end)
            end
        end)
        
        parentFrame.movableNudgeHooked = true
    end
    
    -- Hide nudge when mouse leaves nudge frame (with delay)
    nudge:SetScript("OnEnter", function(self)
        -- Cancel any pending hide timer when entering nudge frame
        if self.hideTimer then
            self.hideTimer:Cancel()
            self.hideTimer = nil
        end
    end)
    
    nudge:SetScript("OnLeave", function(self)
        -- Delay hiding to allow mouse movement
        self.hideTimer = C_Timer.NewTimer(0.3, function()
            if not MouseIsOver(parentFrame) and not MouseIsOver(self) then
                self:Hide()
            end
            self.hideTimer = nil
        end)
    end)
    
    return nudge
end

--[[
    Updates the offset display text on a nudge frame
    @param nudgeFrame - The nudge control frame
    @param db - Database table containing offsetX and offsetY
]]
function Movable:UpdateNudgeDisplay(nudgeFrame, db)
    if nudgeFrame and nudgeFrame.offsetText and db then
        local x = db.offsetX or 0
        local y = db.offsetY or 0
        nudgeFrame.offsetText:SetText(string.format("X: %d  Y: %d", x, y))
    end
end

--[[
    Shows nudge controls anchored near a parent frame
    @param nudgeFrame - The nudge control frame
    @param parentFrame - The frame to anchor near
]]
function Movable:ShowNudgeControls(nudgeFrame, parentFrame)
    if not nudgeFrame or not parentFrame or not MidnightUI.moveMode then return end
    
    -- Cancel any pending hide timer
    if nudgeFrame.hideTimer then
        nudgeFrame.hideTimer:Cancel()
        nudgeFrame.hideTimer = nil
    end
    
    nudgeFrame:ClearAllPoints()
    
    -- Special handling for Minimap - center the nudge frame on it
    if parentFrame == Minimap then
        nudgeFrame:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
    else
        -- Position nudge frame relative to parent's CURRENT position
        local parentX, parentY = parentFrame:GetCenter()
        if parentX and parentY then
            -- If parent is on right half of screen, put nudge on left
            if parentX > UIParent:GetWidth() / 2 then
                nudgeFrame:SetPoint("RIGHT", parentFrame, "LEFT", -10, 0)
            else
                nudgeFrame:SetPoint("LEFT", parentFrame, "RIGHT", 10, 0)
            end
        else
            nudgeFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end
    
    nudgeFrame:Show()
end

--[[
    Hides nudge controls
    @param nudgeFrame - The nudge control frame
]]
function Movable:HideNudgeControls(nudgeFrame)
    if nudgeFrame then
        -- Cancel any pending hide timer
        if nudgeFrame.hideTimer then
            nudgeFrame.hideTimer:Cancel()
            nudgeFrame.hideTimer = nil
        end
        nudgeFrame:Hide()
    end
end

-- ============================================================================
-- 3. MOVE MODE INTEGRATION
-- ============================================================================

function Movable:OnInitialize()
    self:RegisterMessage("MIDNIGHTUI_MOVEMODE_CHANGED", "OnMoveModeChanged")
end

--[[
    Registers a nudge frame to respond to Move Mode changes
    @param nudgeFrame - The nudge control frame
    @param parentFrame - The parent frame (for hover detection)
]]
function Movable:RegisterNudgeFrame(nudgeFrame, parentFrame)
    if not nudgeFrame or not parentFrame then return end
    
    table.insert(self.registeredNudgeFrames, {
        nudge = nudgeFrame,
        parent = parentFrame
    })
end

function Movable:OnMoveModeChanged(event, enabled)
    -- Show/hide green highlights on all registered frames
    for _, frame in ipairs(self.registeredFrames) do
        if frame and frame.movableHighlight then
            if enabled then
                frame.movableHighlight:Show()
            else
                frame.movableHighlight:Hide()
            end
        end
    end
    
    -- When Move Mode is disabled, hide all nudge frames
    if not enabled then
        for _, data in ipairs(self.registeredNudgeFrames) do
            if data.nudge then
                self:HideNudgeControls(data.nudge)
            end
        end
    end
    -- NOTE: When enabled, nudge frames only show on mouseover (except Minimap which shows immediately)
end

-- ============================================================================
-- 4. CONTAINER WITH ARROWS (UIButtons style)
-- ============================================================================

--[[
    Creates nudge arrows positioned around a container (UIButtons style)
    @param container - The container frame
    @param db - Database table with position = {point, x, y}
    @return arrows table with UP, DOWN, LEFT, RIGHT keys
]]
function Movable:CreateContainerArrows(container, db)
    if not container or not db then return end
    
    container.arrows = {}
    
    local directions = {"UP", "DOWN", "LEFT", "RIGHT"}
    
    for _, direction in ipairs(directions) do
        local btn = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
        btn:SetSize(24, 24)
        btn:SetFrameStrata("TOOLTIP")
        btn:SetFrameLevel(300)
        
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        btn:SetBackdropBorderColor(0, 1, 0, 1)
        
        -- Arrow text
        local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        arrow:SetPoint("CENTER")
        
        if direction == "UP" then arrow:SetText("^")
        elseif direction == "DOWN" then arrow:SetText("v")
        elseif direction == "LEFT" then arrow:SetText("<")
        elseif direction == "RIGHT" then arrow:SetText(">")
        end
        
        arrow:SetTextColor(0, 1, 0, 1)
        
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.3, 0.3, 0.3, 1)
        end)
        
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        end)
        
        btn:SetScript("OnClick", function()
            local step = IsShiftKeyDown() and 10 or 1
            
            -- CRITICAL FIX: Get CURRENT position from container, not from DB
            local currentPoint, _, _, currentX, currentY = container:GetPoint()
            
            -- Use current position if DB doesn't have it
            local pos = db.position or {}
            pos.point = pos.point or currentPoint or "CENTER"
            pos.x = pos.x or currentX or 0
            pos.y = pos.y or currentY or 0
            
            if direction == "UP" then
                pos.y = pos.y + step
            elseif direction == "DOWN" then
                pos.y = pos.y - step
            elseif direction == "LEFT" then
                pos.x = pos.x - step
            elseif direction == "RIGHT" then
                pos.x = pos.x + step
            end
            
            -- Save to database
            db.position = pos
            
            -- Update container position
            container:ClearAllPoints()
            container:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
        end)
        
        btn:Hide()
        container.arrows[direction] = btn
    end
    
    -- Setup mouseover for container arrows
    if not container.movableArrowsHooked then
        container:HookScript("OnEnter", function()
            if MidnightUI.moveMode and container.arrows then
                -- Cancel any pending hide timer
                if container.arrowHideTimer then
                    container.arrowHideTimer:Cancel()
                    container.arrowHideTimer = nil
                end
                Movable:UpdateContainerArrows(container)
            end
        end)
        
        container:HookScript("OnLeave", function()
            -- Delay hiding to allow mouse to move to arrows
            container.arrowHideTimer = C_Timer.NewTimer(0.3, function()
                if not MouseIsOver(container) then
                    -- Check if mouse is over any arrow button
                    local overArrow = false
                    for _, arrow in pairs(container.arrows or {}) do
                        if MouseIsOver(arrow) then
                            overArrow = true
                            break
                        end
                    end
                    
                    if not overArrow then
                        Movable:HideContainerArrows(container)
                    end
                end
                container.arrowHideTimer = nil
            end)
        end)
        
        -- Add hover detection for arrow buttons themselves
        for _, arrow in pairs(container.arrows or {}) do
            arrow:HookScript("OnEnter", function()
                if container.arrowHideTimer then
                    container.arrowHideTimer:Cancel()
                    container.arrowHideTimer = nil
                end
            end)
            
            arrow:HookScript("OnLeave", function()
                container.arrowHideTimer = C_Timer.NewTimer(0.3, function()
                    if not MouseIsOver(container) then
                        local overArrow = false
                        for _, btn in pairs(container.arrows or {}) do
                            if MouseIsOver(btn) then
                                overArrow = true
                                break
                            end
                        end
                        
                        if not overArrow then
                            Movable:HideContainerArrows(container)
                        end
                    end
                    container.arrowHideTimer = nil
                end)
            end)
        end
        
        container.movableArrowsHooked = true
    end
    
    return container.arrows
end

--[[
    Updates container arrow positions based on container location
    @param container - The container with .arrows table
]]
function Movable:UpdateContainerArrows(container)
    if not container or not container.arrows then return end
    
    local showArrows = MidnightUI and MidnightUI.moveMode
    
    if not showArrows then
        for _, arrow in pairs(container.arrows) do
            arrow:Hide()
        end
        return
    end
    
    -- Get container position
    local containerY = select(2, container:GetCenter())
    local screenHeight = UIParent:GetHeight()
    
    -- Determine if container is on top or bottom half
    local onTop = containerY > screenHeight / 2
    
    local spacing = 2
    local offset = 5
    
    container.arrows.LEFT:ClearAllPoints()
    container.arrows.UP:ClearAllPoints()
    container.arrows.DOWN:ClearAllPoints()
    container.arrows.RIGHT:ClearAllPoints()
    
    if onTop then
        -- Container on top, arrows below: < ^ v >
        container.arrows.LEFT:SetPoint("TOP", container, "BOTTOM", 0, -offset)
        container.arrows.UP:SetPoint("LEFT", container.arrows.LEFT, "RIGHT", spacing, 0)
        container.arrows.DOWN:SetPoint("LEFT", container.arrows.UP, "RIGHT", spacing, 0)
        container.arrows.RIGHT:SetPoint("LEFT", container.arrows.DOWN, "RIGHT", spacing, 0)
    else
        -- Container on bottom, arrows above: < ^ v >
        container.arrows.LEFT:SetPoint("BOTTOM", container, "TOP", 0, offset)
        container.arrows.UP:SetPoint("LEFT", container.arrows.LEFT, "RIGHT", spacing, 0)
        container.arrows.DOWN:SetPoint("LEFT", container.arrows.UP, "RIGHT", spacing, 0)
        container.arrows.RIGHT:SetPoint("LEFT", container.arrows.DOWN, "RIGHT", spacing, 0)
    end
    
    -- Show all arrows
    for _, arrow in pairs(container.arrows) do
        arrow:Show()
    end
end

--[[
    Hides container arrows
    @param container - The container with .arrows table
]]
function Movable:HideContainerArrows(container)
    if not container or not container.arrows then return end
    
    for _, arrow in pairs(container.arrows) do
        arrow:Hide()
    end
end

return Movable