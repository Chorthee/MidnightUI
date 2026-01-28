local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UIButtons = MidnightUI:NewModule("UIButtons", "AceEvent-3.0")

local buttons = {}

function UIButtons:OnInitialize()
    print("|cff00ff00MidnightUI:|r UIButtons:OnInitialize() called")
    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
    print("|cff00ff00MidnightUI:|r UIButtons registered for MIDNIGHTUI_DB_READY message")
end

function UIButtons:OnDBReady()
    print("|cff00ff00MidnightUI:|r UIButtons:OnDBReady() called!")
    
    -- Check if module is enabled
    if not MidnightUI.db or not MidnightUI.db.profile or not MidnightUI.db.profile.modules then
        print("|cffff0000MidnightUI:|r UIButtons - MidnightUI.db not ready!")
        return
    end
    
    if not MidnightUI.db.profile.modules.buttons then 
        print("|cffff0000MidnightUI:|r UIButtons module is disabled in config")
        return 
    end
    
    print("|cff00ff00MidnightUI:|r UIButtons initializing database...")
    
    self.db = MidnightUI.db:RegisterNamespace("UIButtons", {
        profile = {
            enabled = true,
            scale = 1.0,
            spacing = 2,
            buttons = {
                character = { enabled = true, order = 1 },
                spellbook = { enabled = true, order = 2 },
                talents = { enabled = true, order = 3 },
                achievements = { enabled = true, order = 4 },
                move = { enabled = true, order = 5 }
            }
        }
    })
    
    print("|cff00ff00MidnightUI:|r UIButtons database initialized")
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Register for Move Mode changes using AceEvent's message system
    self:RegisterMessage("MIDNIGHTUI_MOVEMODE_CHANGED", "OnMoveModeChanged")
    
    print("|cff00ff00MidnightUI:|r UIButtons module loaded")
    
    -- Manually call setup since PLAYER_ENTERING_WORLD already fired
    C_Timer.After(0.1, function()
        self:PLAYER_ENTERING_WORLD()
    end)
end

function UIButtons:PLAYER_ENTERING_WORLD()
    print("|cff00ff00MidnightUI:|r UIButtons:PLAYER_ENTERING_WORLD() called")
    self:CreateButtons()
    self:UpdateLayout()
    print("|cff00ff00MidnightUI:|r UIButtons created and positioned")
end

function UIButtons:CreateButtons()
    print("|cff00ff00MidnightUI:|r UIButtons:CreateButtons() starting...")
    
    local buttonData = {
        character = {
            name = "Character",
            icon = "Interface\\PaperDollInfoFrame\\UI-CharacterFrame-Portrait",
            tooltip = "Character Info (C)",
            onClick = function() ToggleCharacter("PaperDollFrame") end
        },
        spellbook = {
            name = "Spellbook",
            icon = "Interface\\MINIMAP\\TRACKING\\Class",
            tooltip = "Spellbook & Abilities (P)",
            onClick = function() if not PlayerSpellsFrame then UIParentLoadAddOn("Blizzard_PlayerSpells") end PlayerSpellsFrame:ToggleFrame() end
        },
        talents = {
            name = "Talents",
            icon = "Interface\\MINIMAP\\TRACKING\\Profession",
            tooltip = "Talents (N)",
            onClick = function()
                if not PlayerSpellsFrame then UIParentLoadAddOn("Blizzard_PlayerSpells") end
                PlayerSpellsFrame:ToggleFrame()
                if PlayerSpellsFrame:IsShown() then
                    PlayerSpellsFrame.TalentsFrame:SetTab(PlayerSpellsFrame.TalentsFrame.tabID)
                end
            end
        },
        achievements = {
            name = "Achievements",
            icon = "Interface\\ACHIEVEMENTFRAME\\UI-ACHIEVEMENT-SHIELD",
            tooltip = "Achievements (Y)",
            onClick = function() ToggleAchievementFrame() end
        },
        move = {
            name = "Move",
            icon = "Interface\\CURSOR\\UI-Cursor-Move",
            tooltip = "Toggle Move Mode\n|cffaaaaaa(Hover over elements to reposition)|r",
            onClick = function() MidnightUI:ToggleMoveMode() end,
            getColor = function()
                if MidnightUI.moveMode then
                    return {0, 1, 0} -- Green when active
                else
                    return {1, 1, 1} -- White when inactive
                end
            end
        }
    }

    local buttonCount = 0
    for key, data in pairs(buttonData) do
        local config = self.db.profile.buttons[key]
        print("|cff00ff00MidnightUI:|r Checking button '"..key.."': enabled="..tostring(config and config.enabled))
        
        if config and config.enabled then
            buttonCount = buttonCount + 1
            print("|cff00ff00MidnightUI:|r Creating button '"..key.."'...")
            
            local btn = CreateFrame("Button", "MidnightUIButton_"..key, UIParent, "SecureActionButtonTemplate")
            btn:SetSize(32, 32)
            btn:RegisterForClicks("AnyUp")
            
            -- CRITICAL FIX: Set VERY HIGH frame strata and level
            btn:SetFrameStrata("TOOLTIP")  -- Changed from "HIGH" to "TOOLTIP" (highest)
            btn:SetFrameLevel(200)  -- Changed from 100 to 200
            
            -- Background
            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            btn.bg = bg
            
            -- Icon
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("CENTER")
            icon:SetSize(24, 24)
            icon:SetTexture(data.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.icon = icon
            
            -- Border
            local border = btn:CreateTexture(nil, "OVERLAY")
            border:SetAllPoints()
            border:SetTexture("Interface\\Buttons\\WHITE8X8")
            border:SetVertexColor(0, 0, 0, 1)
            border:SetDrawLayer("OVERLAY", 7)
            
            -- Hover effect
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
            
            -- Click handler
            btn:SetScript("OnClick", data.onClick)
            
            -- Store data for updates
            btn.key = key
            btn.getData = data.getColor
            
            -- FORCE VISIBILITY AND MOUSE INTERACTION
            btn:Show()
            btn:SetAlpha(1)
            btn:EnableMouse(true)
            
            buttons[key] = btn
            
            -- DEBUG: Print button position after creation
            print("|cff00ff00MidnightUI:|r Button '"..key.."' created - shown="..tostring(btn:IsShown())..", alpha="..btn:GetAlpha()..", strata="..btn:GetFrameStrata())
        end
    end
    
    print("|cff00ff00MidnightUI:|r Total buttons created: "..buttonCount)
    
    -- Register for Move Mode changes to update the Move button color
    self:RegisterMessage("MIDNIGHTUI_MOVEMODE_CHANGED", "OnMoveModeChanged")
end

function UIButtons:OnMoveModeChanged(event, enabled)
    local moveBtn = buttons.move
    if moveBtn and moveBtn.icon then
        local color = enabled and {0, 1, 0} or {1, 1, 1}
        moveBtn.icon:SetVertexColor(unpack(color))
    end
end

function UIButtons:UpdateLayout()
    print("|cff00ff00MidnightUI:|r UIButtons:UpdateLayout() called")
    
    local sortedButtons = {}
    
    for key, btn in pairs(buttons) do
        local order = self.db.profile.buttons[key].order or 999
        table.insert(sortedButtons, {key = key, btn = btn, order = order})
    end
    
    table.sort(sortedButtons, function(a, b) return a.order < b.order end)
    
    local scale = self.db.profile.scale
    local spacing = self.db.profile.spacing
    
    print("|cff00ff00MidnightUI:|r Positioning "..#sortedButtons.." buttons with scale="..scale..", spacing="..spacing)
    
    for i, data in ipairs(sortedButtons) do
        data.btn:ClearAllPoints()
        data.btn:SetScale(scale)
        
        if i == 1 then
            data.btn:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 10)
            print("|cff00ff00MidnightUI:|r Button '"..data.key.."' positioned at BOTTOMRIGHT")
        else
            local prevBtn = sortedButtons[i-1].btn
            data.btn:SetPoint("RIGHT", prevBtn, "LEFT", -spacing, 0)
            print("|cff00ff00MidnightUI:|r Button '"..data.key.."' positioned to left of previous button")
        end
        
        -- Double check it's shown
        data.btn:Show()
    end
    
    print("|cff00ff00MidnightUI:|r UIButtons layout complete")
end

function UIButtons:GetOptions()
    return {
        type = "group",
        name = "UI Buttons",
        order = 10,
        args = {
            header = {
                type = "header",
                name = "Quick Access Buttons",
                order = 1
            },
            desc = {
                type = "description",
                name = "Buttons appear in the bottom-right corner for quick access to common UI panels.",
                order = 2
            },
            scale = {
                name = "Scale",
                type = "range",
                order = 3,
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
                order = 4,
                min = 0,
                max = 20,
                step = 1,
                get = function() return self.db.profile.spacing end,
                set = function(_, v)
                    self.db.profile.spacing = v
                    self:UpdateLayout()
                end
            },
            buttonsHeader = {
                type = "header",
                name = "Individual Buttons",
                order = 10
            },
            character = {
                name = "Character (C)",
                type = "toggle",
                order = 11,
                get = function() return self.db.profile.buttons.character.enabled end,
                set = function(_, v)
                    self.db.profile.buttons.character.enabled = v
                    ReloadUI()
                end
            },
            spellbook = {
                name = "Spellbook (P)",
                type = "toggle",
                order = 12,
                get = function() return self.db.profile.buttons.spellbook.enabled end,
                set = function(_, v)
                    self.db.profile.buttons.spellbook.enabled = v
                    ReloadUI()
                end
            },
            talents = {
                name = "Talents (N)",
                type = "toggle",
                order = 13,
                get = function() return self.db.profile.buttons.talents.enabled end,
                set = function(_, v)
                    self.db.profile.buttons.talents.enabled = v
                    ReloadUI()
                end
            },
            achievements = {
                name = "Achievements (Y)",
                type = "toggle",
                order = 14,
                get = function() return self.db.profile.buttons.achievements.enabled end,
                set = function(_, v)
                    self.db.profile.buttons.achievements.enabled = v
                    ReloadUI()
                end
            },
            move = {
                name = "Move Mode (M)",
                type = "toggle",
                order = 15,
                get = function() return self.db.profile.buttons.move.enabled end,
                set = function(_, v)
                    self.db.profile.buttons.move.enabled = v
                    ReloadUI()
                end
            }
        }
    }
end