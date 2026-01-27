local MidnightUI = LibStub("AceAddon-3.0"):NewAddon("MidnightUI", "AceConsole-3.0", "AceEvent-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

MidnightUI.version = "1.0.0"

-- ============================================================================
-- 1. DATABASE DEFAULTS
-- ============================================================================
local defaults = {
    profile = {
        theme = {
            font = "Friz Quadrata TT",
            fontSize = 12,
            bgColor = {0.1, 0.1, 0.1, 0.8},
            borderColor = {0, 0, 0, 1},
        },
        modules = {
            bar = true,
            buttons = true,
            maps = true,
            actionbars = true,
            unitframes = true,
            cooldowns = true,
            tweaks = true
        }
    }
}

-- ============================================================================
-- 2. INITIALIZATION
-- ============================================================================
function MidnightUI:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MidnightUIDB", self:GetDefaults(), true)
    
    -- Register slash commands
    self:RegisterChatCommand("mui", "SlashCommand")
    self:RegisterChatCommand("midnightui", "SlashCommand")
    self:RegisterChatCommand("muimove", "ToggleMoveMode")
end

function MidnightUI:SlashCommand(input)
    if not input or input:trim() == "" then
        self:OpenConfig()
    elseif input:lower() == "move" then
        self:ToggleMoveMode()
    else
        self:OpenConfig()
    end
end

-- ============================================================================
-- 3. UTILITY FUNCTIONS
-- ============================================================================
function MidnightUI:OpenConfig()
    if Settings and Settings.OpenToCategory then
        local categoryID = nil
        if SettingsPanel and SettingsPanel.GetCategoryList then
            for _, category in ipairs(SettingsPanel:GetCategoryList()) do
                if category.name == "Midnight UI" then
                    categoryID = category:GetID()
                    break
                end
            end
        end
        if categoryID then Settings.OpenToCategory(categoryID); return end
    end
    
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("Midnight UI")
    else
        LibStub("AceConfigDialog-3.0"):Open("MidnightUI")
    end
end

function MidnightUI:SkinFrame(frame)
    if not frame then return end
    if not frame.muiBackdrop then
        frame.muiBackdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.muiBackdrop:SetAllPoints()
        local level = frame:GetFrameLevel()
        frame.muiBackdrop:SetFrameLevel(level > 0 and level - 1 or 0)
        frame.muiBackdrop:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
    end
    local cfg = self.db.profile.theme
    frame.muiBackdrop:SetBackdropColor(unpack(cfg.bgColor))
    frame.muiBackdrop:SetBackdropBorderColor(unpack(cfg.borderColor))
end

-- ============================================================================
-- 4. OPTIONS TABLE
-- ============================================================================
function MidnightUI:GetOptions()
    local options = {
        name = "Midnight UI",
        type = "group",
        childGroups = "tab",
        args = {
            general = {
                name = "General",
                type = "group",
                order = 1,
                args = {
                    header = { type = "header", order = 1, name = "Modules" },
                    desc = { type = "description", order = 2, name = "Toggle modules. Requires Reload." },
                    bar = { name = "Data Brokers", type = "toggle", order = 3, width = "full",
                        get = function() return self.db.profile.modules.bar end,
                        set = function(_, v) self.db.profile.modules.bar = v; C_UI.Reload() end },
                    buttons = { name = "UI Buttons", type = "toggle", order = 4, width = "full",
                        get = function() return self.db.profile.modules.buttons end,
                        set = function(_, v) self.db.profile.modules.buttons = v; C_UI.Reload() end },
                    maps = { name = "Maps", type = "toggle", order = 5, width = "full",
                        get = function() return self.db.profile.modules.maps end,
                        set = function(_, v) self.db.profile.modules.maps = v; C_UI.Reload() end },
                    actionbars = { name = "Action Bars", type = "toggle", order = 6, width = "full",
                        get = function() return self.db.profile.modules.actionbars end,
                        set = function(_, v) self.db.profile.modules.actionbars = v; C_UI.Reload() end },
                    unitframes = { name = "Unit Frames", type = "toggle", order = 7, width = "full",
                        get = function() return self.db.profile.modules.unitframes end,
                        set = function(_, v) self.db.profile.modules.unitframes = v; C_UI.Reload() end },
                    cooldowns = { name = "Cooldown Text", type = "toggle", order = 8, width = "full",
                        get = function() return self.db.profile.modules.cooldowns end,
                        set = function(_, v) self.db.profile.modules.cooldowns = v; C_UI.Reload() end },
                    tweaks = { name = "Tweaks", type = "toggle", order = 9, width = "full",
                        get = function() return self.db.profile.modules.tweaks end,
                        set = function(_, v) self.db.profile.modules.tweaks = v; C_UI.Reload() end },
                }
            },
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
        }
    }
    options.args.profiles.order = 100
    
    -- Inject Module Options with RENAMING
    for name, module in self:IterateModules() do
        if module.GetOptions and self.db.profile.modules[string.lower(name)] then
            local displayName = name
            
            -- RENAME LOGIC
            if name == "Buttons" or name == "UIButtons" then displayName = "UI Buttons"
            elseif name == "Bar" then displayName = "Data Brokers" end
            
            options.args[name] = module:GetOptions()
            options.args[name].name = displayName
            options.args[name].order = 10
        end
    end
    return options
end

-- Add Move Mode property
MidnightUI.moveMode = false

-- Add Move Mode toggle function
function MidnightUI:ToggleMoveMode()
    self.moveMode = not self.moveMode
    
    if self.moveMode then
        print("|cff00ff00MidnightUI:|r Move Mode |cff00ff00ENABLED|r - Hover over elements to move them")
    else
        print("|cff00ff00MidnightUI:|r Move Mode |cffff0000DISABLED|r")
    end
    
    -- Notify all modules about move mode change
    self:SendMessage("MIDNIGHTUI_MOVEMODE_CHANGED", self.moveMode)
end