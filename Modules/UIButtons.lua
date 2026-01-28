local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UIButtons = MidnightUI:NewModule("UIButtons", "AceEvent-3.0")

local uiButtons = {}
local container

function UIButtons:OnInitialize()
    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
end

function UIButtons:OnDBReady()
    if not MidnightUI.db or not MidnightUI.db.profile or not MidnightUI.db.profile.modules then
        return
    end
    
    if not MidnightUI.db.profile.modules.UIButtons then
        return 
    end
    
    self.db = MidnightUI.db:RegisterNamespace("UIButtons", {
        profile = {
            enabled = true,
            scale = 1.0,
            spacing = 2,
            locked = false,
            position = { point = "BOTTOMRIGHT", x = -10, y = 10 },
            backgroundColor = { 0.1, 0.1, 0.1, 0.8 },
            UIButtons = {
                reload = { enabled = true, order = 1 },
                exit = { enabled = true, order = 2 },
                logout = { enabled = true, order = 3 },
                addons = { enabled = true, order = 4 },
                move = { enabled = true, order = 5 }
            }
        }
    })
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterMessage("MIDNIGHTUI_MOVEMODE_CHANGED", "OnMoveModeChanged")
    
    -- Manually call setup since PLAYER_ENTERING_WORLD already fired
    C_Timer.After(0.1, function()
        self:PLAYER_ENTERING_WORLD()
    end)
end

function UIButtons:PLAYER_ENTERING_WORLD()
    self:CreateContainer()
    self:CreateButtons()
    self:UpdateLayout()
end

function UIButtons:CreateContainer()
    if container then return end
    
    container = CreateFrame("Frame", "MidnightUI_UIButtonsContainer", UIParent, "BackdropTemplate")
    container:SetSize(200, 36)  -- Will be resized based on buttons
    
    local pos = self.db.profile.position
    container:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    container:SetScale(self.db.profile.scale)
    container:SetFrameStrata("TOOLTIP")
    container:SetFrameLevel(200)
    container:EnableMouse(true)
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    
    -- Background
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    container:SetBackdropColor(unpack(self.db.profile.backgroundColor))
    container:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Drag functionality
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            local ctrlAlt = IsControlKeyDown() and IsAltKeyDown()
            local moveMode = MidnightUI and MidnightUI.moveMode
            if ctrlAlt or moveMode then
                self:StartMoving()
            end
        end
    end)
    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        UIButtons.db.profile.position = { point = point, x = x, y = y }
        UIButtons:UpdateNudgeArrows()
    end)
    
    container:Show()
    self:CreateNudgeArrows()
end

function UIButtons:CreateNudgeArrows()
    if not container then return end
    
    container.arrows = {}
    
    local directions = {"UP", "DOWN", "LEFT", "RIGHT"}
    
    for _, direction in ipairs(directions) do
        local btn = CreateFrame("Button", "MidnightUI_UIButtonsNudge_"..direction, UIParent, "BackdropTemplate")
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
            local pos = UIButtons.db.profile.position
            
            if direction == "UP" then
                pos.y = pos.y + step
            elseif direction == "DOWN" then
                pos.y = pos.y - step
            elseif direction == "LEFT" then
                pos.x = pos.x - step
            elseif direction == "RIGHT" then
                pos.x = pos.x + step
            end
            
            container:ClearAllPoints()
            container:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
            UIButtons:UpdateNudgeArrows()
        end)
        
        btn:Hide()
        container.arrows[direction] = btn
    end
    
    self:UpdateNudgeArrows()
end

function UIButtons:UpdateNudgeArrows()
    if not container or not container.arrows then return end
    
    local showArrows = MidnightUI and MidnightUI.moveMode
    
    if not showArrows then
        for _, arrow in pairs(container.arrows) do
            arrow:Hide()
        end
        return
    end
    
    -- Get container position
    local containerX = container:GetCenter()
    local containerY = select(2, container:GetCenter())
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    
    -- Determine which side of screen container is on
    local onLeft = containerX < screenWidth / 2
    local onTop = containerY > screenHeight / 2
    
    -- Position arrows intelligently
    local spacing = 30
    
    -- Vertical arrows (above or below based on position)
    if onTop then
        -- Container is on top, put arrows below
        container.arrows.UP:SetPoint("TOP", container, "BOTTOM", -spacing, -5)
        container.arrows.DOWN:SetPoint("TOP", container, "BOTTOM", spacing, -5)
    else
        -- Container is on bottom, put arrows above
        container.arrows.UP:SetPoint("BOTTOM", container, "TOP", -spacing, 5)
        container.arrows.DOWN:SetPoint("BOTTOM", container, "TOP", spacing, 5)
    end
    
    -- Horizontal arrows (same level as container)
    if onLeft then
        -- Container is on left, put arrows on right
        container.arrows.LEFT:SetPoint("LEFT", container, "RIGHT", 5, 0)
        container.arrows.RIGHT:SetPoint("LEFT", container.arrows.LEFT, "RIGHT", 2, 0)
    else
        -- Container is on right, put arrows on left
        container.arrows.RIGHT:SetPoint("RIGHT", container, "LEFT", -5, 0)
        container.arrows.LEFT:SetPoint("RIGHT", container.arrows.RIGHT, "LEFT", -2, 0)
    end
    
    -- Show all arrows
    for _, arrow in pairs(container.arrows) do
        arrow:Show()
    end
end

function UIButtons:CreateButtons()
    local buttonData = {
        reload = {
            name = "Reload",
            text = "R",
            tooltip = "Reload UI",
            onClick = function() ReloadUI() end
        },
        exit = {
            name = "Exit",
            text = "E",
            tooltip = "Exit Game",
            onClick = function() Quit() end
        },
        logout = {
            name = "Logout",
            text = "L",
            tooltip = "Logout to Character Select",
            onClick = function() Logout() end
        },
        addons = {
            name = "Addons",
            text = "A",
            tooltip = "Open Addon List"
        },
        move = {
            name = "Move",
            text = "M",
            tooltip = "Toggle Move Mode\n|cffaaaaaa(Hover over elements to reposition)|r",
            onClick = function() 
                MidnightUI:ToggleMoveMode()
                UIButtons:UpdateNudgeArrows()
            end,
            getColor = function()
                if MidnightUI.moveMode then
                    return {0, 1, 0}
                else
                    return {1, 1, 1}
                end
            end
        }
    }

    for key, data in pairs(buttonData) do
        local config = self.db.profile.UIButtons[key]
        
        if config and config.enabled then
            
            local btn = CreateFrame("Button", "MidnightUIButton_"..key, container, "SecureActionButtonTemplate")
            btn:SetSize(32, 32)
            btn:SetFrameStrata("TOOLTIP")
            btn:SetFrameLevel(201)
            btn:EnableMouse(true)
            
            -- Set up secure attributes for logout/exit/addons buttons FIRST
            if key == "logout" then
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", "/logout")
                btn:RegisterForClicks("AnyUp", "AnyDown")
            elseif key == "exit" then
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", "/quit")
                btn:RegisterForClicks("AnyUp", "AnyDown")
            elseif key == "addons" then
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", "/addons")
                btn:RegisterForClicks("AnyUp", "AnyDown")
            else
                btn:RegisterForClicks("AnyUp")
            end            
            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            btn.bg = bg
            
            local text = btn:CreateFontString(nil, "OVERLAY")
            text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
            text:SetPoint("CENTER")
            text:SetText(data.text)
            text:SetTextColor(1, 1, 1, 1)
            btn.text = text
            
            local border = btn:CreateTexture(nil, "OVERLAY")
            border:SetAllPoints()
            border:SetTexture("Interface\\Buttons\\WHITE8X8")
            border:SetVertexColor(0, 0, 0, 1)
            border:SetDrawLayer("OVERLAY", 7)
            
            btn:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(0.2, 0.2, 0.2, 1)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(data.tooltip)
                GameTooltip:Show()
            end)
            
            btn:SetScript("OnLeave", function(self)
                self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                GameTooltip:Hide()
            end)
            
            -- Click handler (only for non-secure buttons)
            if key ~= "logout" and key ~= "exit" and key ~= "addons" then
                btn:SetScript("OnClick", data.onClick)
            end
            
            btn.key = key
            btn.getData = data.getColor
            btn:Show()
            btn:SetAlpha(1)
            
            uiButtons[key] = btn  -- Changed variable name
        end
    end
    
    self:RegisterMessage("MIDNIGHTUI_MOVEMODE_CHANGED", "OnMoveModeChanged")
end

function UIButtons:OnMoveModeChanged(event, enabled)
    local moveBtn = uiButtons.move  -- Changed variable name
    if moveBtn and moveBtn.text then
        local color = enabled and {0, 1, 0} or {1, 1, 1}
        moveBtn.text:SetTextColor(unpack(color))
    end
end

function UIButtons:UpdateLayout()
    if not container then return end
    
    local sortedButtons = {}
    
    for key, btn in pairs(uiButtons) do
        local order = self.db.profile.UIButtons[key].order or 999
        table.insert(sortedButtons, {key = key, btn = btn, order = order})
    end
    
    table.sort(sortedButtons, function(a, b) return a.order < b.order end)
    
    local spacing = self.db.profile.spacing
    local buttonWidth = 32
    local totalWidth = (#sortedButtons * buttonWidth) + ((#sortedButtons - 1) * spacing) + 6
    
    container:SetSize(totalWidth, 36)
    container:SetScale(self.db.profile.scale)
    container:SetBackdropColor(unpack(self.db.profile.backgroundColor))
    
    -- Position buttons from left to right
    for i, data in ipairs(sortedButtons) do
        data.btn:ClearAllPoints()
        
        if i == 1 then
            data.btn:SetPoint("LEFT", container, "LEFT", 3, 0)
        else
            local prevBtn = sortedButtons[i-1].btn
            data.btn:SetPoint("LEFT", prevBtn, "RIGHT", spacing, 0)
        end
        
        data.btn:Show()
    end
end

function UIButtons:GetOptions()
    return {
        type = "group",
        name = "UI Buttons",
        order = 10,
        args = {
            header = { type = "header", name = "Quick Access Buttons", order = 1 },
            desc = { type = "description", name = "Buttons appear in a container that can be moved and customized.", order = 2 },
            locked = {
                name = "Lock Position",
                type = "toggle",
                order = 3,
                get = function() return self.db.profile.locked end,
                set = function(_, v) self.db.profile.locked = v end
            },
            scale = {
                name = "Scale",
                type = "range",
                order = 4,
                min = 0.5,
                max = 2.0,
                step = 0.1,
                get = function() return self.db.profile.scale end,
                set = function(_, v)
                    self.db.profile.scale = v
                    self:UpdateLayout()
                end
            },
            spacing = {
                name = "Spacing",
                type = "range",
                order = 5,
                min = 0,
                max = 20,
                step = 1,
                get = function() return self.db.profile.spacing end,
                set = function(_, v)
                    self.db.profile.spacing = v
                    self:UpdateLayout()
                end
            },
            backgroundColor = {
                name = "Background Color",
                type = "color",
                order = 6,
                hasAlpha = true,
                get = function()
                    local c = self.db.profile.backgroundColor
                    return c[1], c[2], c[3], c[4]
                end,
                set = function(_, r, g, b, a)
                    self.db.profile.backgroundColor = {r, g, b, a}
                    self:UpdateLayout()
                end
            },
            buttonsHeader = { type = "header", name = "Individual Buttons", order = 10 },
            reload = {
                name = "Reload (R)", type = "toggle", order = 11,
                get = function() return self.db.profile.UIButtons.reload.enabled end,
                set = function(_, v) self.db.profile.UIButtons.reload.enabled = v; ReloadUI() end
            },
            exit = {
                name = "Exit (E)", type = "toggle", order = 12,
                get = function() return self.db.profile.UIButtons.exit.enabled end,
                set = function(_, v) self.db.profile.UIButtons.exit.enabled = v; ReloadUI() end
            },
            logout = {
                name = "Logout (L)", type = "toggle", order = 13,
                get = function() return self.db.profile.UIButtons.logout.enabled end,
                set = function(_, v) self.db.profile.UIButtons.logout.enabled = v; ReloadUI() end
            },
            addons = {
                name = "Addons (A)", type = "toggle", order = 14,
                get = function() return self.db.profile.UIButtons.addons.enabled end,
                set = function(_, v) self.db.profile.UIButtons.addons.enabled = v; ReloadUI() end
            },
            move = {
                name = "Move Mode (M)", type = "toggle", order = 15,
                get = function() return self.db.profile.UIButtons.move.enabled end,
                set = function(_, v) self.db.profile.UIButtons.move.enabled = v; ReloadUI() end
            }
        }
    }
end