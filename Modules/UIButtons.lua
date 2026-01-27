local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UIButtons = MidnightUI:NewModule("UIButtons", "AceEvent-3.0")

local buttons = {}

function UIButtons:OnInitialize()
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
    
    if not MidnightUI.db.profile.modules.buttons then return end
    
    self:CreateButtons()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateLayout")
end

function UIButtons:CreateButtons()
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

    for key, data in pairs(buttonData) do
        local config = self.db.profile.buttons[key]
        if config and config.enabled then
            local btn = CreateFrame("Button", "MidnightUIButton_"..key, UIParent, "SecureActionButtonTemplate")
            btn:SetSize(32, 32)
            btn:RegisterForClicks("AnyUp")
            
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
            
            buttons[key] = btn
        end
    end
    
    -- Register for Move Mode changes to update the Move button color
    MidnightUI.RegisterCallback(self, "MIDNIGHTUI_MOVEMODE_CHANGED", "OnMoveModeChanged")
end

function UIButtons:OnMoveModeChanged(event, enabled)
    local moveBtn = buttons.move
    if moveBtn and moveBtn.icon then
        local color = enabled and {0, 1, 0} or {1, 1, 1}
        moveBtn.icon:SetVertexColor(unpack(color))
    end
end

function UIButtons:UpdateLayout()
    local sortedButtons = {}
    
    for key, btn in pairs(buttons) do
        local order = self.db.profile.buttons[key].order or 999
        table.insert(sortedButtons, {key = key, btn = btn, order = order})
    end
    
    table.sort(sortedButtons, function(a, b) return a.order < b.order end)
    
    local scale = self.db.profile.scale
    local spacing = self.db.profile.spacing
    local totalWidth = 0
    
    for i, data in ipairs(sortedButtons) do
        data.btn:ClearAllPoints()
        data.btn:SetScale(scale)
        
        if i == 1 then
            data.btn:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 10)
        else
            local prevBtn = sortedButtons[i-1].btn
            data.btn:SetPoint("RIGHT", prevBtn, "LEFT", -spacing, 0)
        end
        
        totalWidth = totalWidth + (32 * scale) + spacing
    end
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