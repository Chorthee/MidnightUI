local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UIButtons = MidnightUI:NewModule("UIButtons", "AceEvent-3.0")

local uiButtons = {}  -- Changed variable name to avoid conflict with module name

function UIButtons:OnInitialize()
    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
end

function UIButtons:OnDBReady()
    if not MidnightUI.db or not MidnightUI.db.profile or not MidnightUI.db.profile.modules then
        return
    end
    
    if not MidnightUI.db.profile.modules.UIButtons then  -- Changed from buttons
        return 
    end
    
    self.db = MidnightUI.db:RegisterNamespace("UIButtons", {
        profile = {
            enabled = true,
            scale = 1.0,
            spacing = 2,
            UIButtons = {  -- Changed from buttons
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
    self:CreateButtons()
    self:UpdateLayout()
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
            tooltip = "Open Addons List",
            onClick = function() 
                if AddonList then
                    -- Legacy addon list
                    if AddonList:IsShown() then
                        AddonList:Hide()
                    else
                        AddonList:Show()
                    end
                elseif SettingsPanel then
                    -- Modern WoW - toggle Settings panel
                    if SettingsPanel:IsShown() then
                        SettingsPanel:Close()
                    else
                        SettingsPanel:Open()
                    end
                elseif Settings then
                    Settings.OpenToCategory()
                end
            end
        },
        move = {
            name = "Move",
            text = "M",
            tooltip = "Toggle Move Mode\n|cffaaaaaa(Hover over elements to reposition)|r",
            onClick = function() MidnightUI:ToggleMoveMode() end,
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
        local config = self.db.profile.UIButtons[key]  -- Changed
        
        if config and config.enabled then
            
            local btn = CreateFrame("Button", "MidnightUIButton_"..key, UIParent, "SecureActionButtonTemplate")
            btn:SetSize(32, 32)
            btn:SetFrameStrata("TOOLTIP")
            btn:SetFrameLevel(200)            
            -- Set up secure attributes for logout/exit buttons
            if key == "logout" then
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", "/camp")
                btn:RegisterForClicks("LeftButtonUp")
            elseif key == "exit" then
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", "/quit")
                btn:RegisterForClicks("LeftButtonUp")
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
            if key ~= "logout" and key ~= "exit" then
                btn:SetScript("OnClick", data.onClick)
            end
            
            btn.key = key
            btn.getData = data.getColor
            btn:Show()
            btn:SetAlpha(1)
            btn:EnableMouse(true)
            
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
    local sortedButtons = {}
    
    for key, btn in pairs(uiButtons) do  -- Changed variable name
        local order = self.db.profile.UIButtons[key].order or 999  -- Changed
        table.insert(sortedButtons, {key = key, btn = btn, order = order})
    end
    
    table.sort(sortedButtons, function(a, b) return a.order < b.order end)
    
    local scale = self.db.profile.scale
    local spacing = self.db.profile.spacing
    
    for i = #sortedButtons, 1, -1 do
        local data = sortedButtons[i]
        data.btn:ClearAllPoints()
        data.btn:SetScale(scale)
        
        if i == #sortedButtons then
            data.btn:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 10)
        else
            local nextBtn = sortedButtons[i+1].btn
            data.btn:SetPoint("RIGHT", nextBtn, "LEFT", -spacing, 0)
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
            desc = { type = "description", name = "Buttons appear in the bottom-right corner for quick access to common UI panels.", order = 2 },
            scale = {
                name = "Scale", type = "range", order = 3, min = 0.5, max = 2.0, step = 0.1,
                get = function() return self.db.profile.scale end,
                set = function(_, v) self.db.profile.scale = v; self:UpdateLayout() end
            },
            spacing = {
                name = "Spacing", type = "range", order = 4, min = 0, max = 20, step = 1,
                get = function() return self.db.profile.spacing end,
                set = function(_, v) self.db.profile.spacing = v; self:UpdateLayout() end
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