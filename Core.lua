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
            skins = true,
            bar = true,
            UIButtons = true,
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
    self.db = LibStub("AceDB-3.0"):New("MidnightUIDB", defaults, true)
    
    -- Register slash commands
    self:RegisterChatCommand("mui", "SlashCommand")
    self:RegisterChatCommand("midnightui", "SlashCommand")
    self:RegisterChatCommand("muimove", "ToggleMoveMode")
end

function MidnightUI:OnEnable()
    -- Send the message after all modules have registered
    C_Timer.After(0.1, function()
        self:SendMessage("MIDNIGHTUI_DB_READY")
    end)
    
    -- Register options after modules load
    C_Timer.After(0.2, function()
        AceConfig:RegisterOptionsTable("MidnightUI", function() return self:GetOptions() end)
        AceConfigDialog:AddToBlizOptions("MidnightUI", "Midnight UI")
        -- Set a larger default size for the options window
        if AceConfigDialog.SetDefaultSize then
            AceConfigDialog:SetDefaultSize("MidnightUI", 900, 700)
        end
    end)
    
    -- Load Focus Frame if present
    if UnitFrames and UnitFrames.CreateFocusFrame then
        UnitFrames:CreateFocusFrame()
    end
end

function MidnightUI:SlashCommand(input)
    if not input or input:trim() == "" then
        self:OpenConfig()
    elseif input:lower() == "move" then
        self:ToggleMoveMode()
    else
--        self:OpenConfig()
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
                    globalFont = {
                        type = "select",
                        name = "Global Font",
                        desc = "Select a font to apply to all MidnightUI elements.",
                        order = 2.1,
                        values = function()
                            local fonts = LSM:List("font")
                            local out = {}
                            for _, font in ipairs(fonts) do out[font] = font end
                            return out
                        end,
                        get = function() return self.db.profile.theme.font or "Friz Quadrata TT" end,
                        set = function(_, v) self.db.profile.theme.font = v end,
                    },
                    applyGlobalFont = {
                        type = "execute",
                        name = "Apply to All",
                        desc = "Apply the selected global font to all MidnightUI modules and bars.",
                        order = 2.2,
                        func = function()
                            local font = MidnightUI.db.profile.theme.font or "Friz Quadrata TT"
                            -- UnitFrames
                            if _G.UnitFrames and _G.UnitFrames.db and _G.UnitFrames.db.profile then
                                local uf = _G.UnitFrames.db.profile
                                for _, frame in pairs({"player", "target", "targettarget"}) do
                                    for _, bar in pairs({"health", "power", "info"}) do
                                        if uf[frame] and uf[frame][bar] then
                                            uf[frame][bar].font = font
                                        end
                                    end
                                end
                            end
                            -- Bar module: set all bar fonts to global and update
                            if _G.Bar and _G.Bar.db and _G.Bar.db.profile and _G.Bar.db.profile.bars then
                                for barID, barData in pairs(_G.Bar.db.profile.bars) do
                                    barData.font = font
                                end
                                if _G.Bar.UpdateAllFonts then
                                    _G.Bar:UpdateAllFonts()
                                end
                            end
                            -- Cooldowns module
                            if _G.Cooldowns and _G.Cooldowns.db and _G.Cooldowns.db.profile then
                                _G.Cooldowns.db.profile.font = font
                            end
                            -- Maps module
                            if _G.Maps and _G.Maps.db and _G.Maps.db.profile then
                                _G.Maps.db.profile.font = font
                            end
                            -- ActionBars module
                            if _G.ActionBars and _G.ActionBars.db and _G.ActionBars.db.profile then
                                _G.ActionBars.db.profile.font = font
                            end
                            -- UIButtons module
                            if _G.UIButtons and _G.UIButtons.db and _G.UIButtons.db.profile then
                                _G.UIButtons.db.profile.font = font
                            end
                            -- Tweaks module
                            if _G.Tweaks and _G.Tweaks.db and _G.Tweaks.db.profile then
                                _G.Tweaks.db.profile.font = font
                            end
                            -- Skins module
                            if _G.Skins and _G.Skins.db and _G.Skins.db.profile then
                                _G.Skins.db.profile.font = font
                            end
                            -- Movable module
                            if _G.Movable and _G.Movable.db and _G.Movable.db.profile then
                                _G.Movable.db.profile.font = font
                            end
                            -- Force UI update for UnitFrames
                            if _G.UnitFrames and _G.UnitFrames.UpdateUnitFrame then
                                _G.UnitFrames:UpdateUnitFrame("PlayerFrame", "player")
                                _G.UnitFrames:UpdateUnitFrame("TargetFrame", "target")
                                _G.UnitFrames:UpdateUnitFrame("TargetTargetFrame", "targettarget")
                            end
                            -- Add update calls for other modules as needed
                        end,
                    },
                    bar = { name = "Data Brokers", type = "toggle", order = 3, width = "full",
                        get = function() return self.db.profile.modules.bar end,
                        set = function(_, v) self.db.profile.modules.bar = v; C_UI.Reload() end },
                    UIButtons = { name = "UI Buttons", type = "toggle", order = 4, width = "full",
                        get = function() return self.db.profile.modules.UIButtons end,
                        set = function(_, v) self.db.profile.modules.UIButtons = v; C_UI.Reload() end },
                    chatcopy = { name = "Chat Copy", type = "toggle", order = 4.5, width = "full",
                        get = function() return self.db.profile.modules.chatcopy ~= false end,
                        set = function(_, v) self.db.profile.modules.chatcopy = v; C_UI.Reload() end },
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
                        set = function(_, v) self.db.profile.modules.tweaks = v; C_UI.Reload() end }
                }  -- closes args table for general
            },  -- closes general group
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
        }  -- closes main args table
    }  -- closes options table
    
    options.args.profiles.order = 100
    
    -- Inject Module Options
    for name, module in self:IterateModules() do
        -- Map module names to their database keys
        local dbKey = name
        if name == "UIButtons" then 
            dbKey = "UIButtons"
        elseif name == "Skin" then
            dbKey = "skins"
        elseif name == "Bar" then
            dbKey = "bar"
        elseif name == "Maps" then
            dbKey = "maps"
        elseif name == "ActionBars" then
            dbKey = "actionbars"
        elseif name == "UnitFrames" then
            dbKey = "unitframes"
        elseif name == "Cooldowns" then
            dbKey = "cooldowns"
        elseif name == "Tweaks" then
            dbKey = "tweaks"
        else
            dbKey = string.lower(name)
        end
        
        if module.GetOptions and self.db.profile.modules[dbKey] then
            local displayName = name
            if name == "UIButtons" then 
                displayName = "UI Buttons"
            elseif name == "Skin" then
                displayName = "Skinning"
            elseif name == "Bar" then 
                displayName = "Data Brokers"
            end
            if name == "UnitFrames" then
                options.args.unitframes = module:GetOptions()
                options.args.unitframes.name = "Unit Frames"
                options.args.unitframes.order = 8
            else
                options.args[name] = module:GetOptions()
                options.args[name].name = displayName
                options.args[name].order = 10
            end
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
    
    -- Use AceEvent's SendMessage (already loaded)
    self:SendMessage("MIDNIGHTUI_MOVEMODE_CHANGED", self.moveMode)
    -- Directly call Movable:OnMoveModeChanged for reliability
    local Movable
    if self.GetModule then
        Movable = self:GetModule("Movable", true)
    end
    if Movable and Movable.OnMoveModeChanged then
        Movable:OnMoveModeChanged("MIDNIGHTUI_MOVEMODE_CHANGED", self.moveMode)
    end
    
end