local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local Skin = MidnightUI:NewModule("Skin", "AceEvent-3.0", "AceHook-3.0")

-- ============================================================================
-- SKIN DEFINITIONS
-- ============================================================================

local SKINS = {
    ["Midnight"] = {
        backdrop = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = nil,
            tile = false, tileSize = 0, edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        },
        bgColor = {0.1, 0.1, 0.1, 0.8},
        borderColor = {0, 0, 0, 1},
        borderAlpha = 0
    },
    ["Blizzard"] = {
        backdrop = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        },
        bgColor = {0, 0, 0, 0.8},
        borderColor = {1, 1, 1, 1},
        borderAlpha = 1
    },
    ["Glass"] = {
        backdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        },
        bgColor = {0.1, 0.1, 0.1, 0.3},
        borderColor = {0, 0, 0, 1},
        borderAlpha = 0.4
    },
    ["Flat"] = {
        backdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        },
        bgColor = {0, 0, 0, 0.9},
        borderColor = {0.3, 0.3, 0.3, 1},
        borderAlpha = 1
    }
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function Skin:OnInitialize()
    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
end

function Skin:OnDBReady()
    self.db = MidnightUI.db:RegisterNamespace("Skin", {
        profile = {
            globalSkin = "Midnight",
            skinActionBars = true,
            skinDataBrokerBars = true,
            skinUIButtons = true,
            skinMinimap = true,
            skinTooltips = true,
            skinChatFrames = false,
            skinUnitFrames = false,  -- Disabled by default due to Blizzard conflicts
            skinBags = true,
            skinBlizzardFrames = true,
            buttonBackgroundColor = {0.1, 0.1, 0.1, 0.8},
            buttonBorderColor = {0, 0, 0, 1}
        }
    })
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Immediately trigger skinning since we may have already entered world
    C_Timer.After(0.1, function()
        self:PLAYER_ENTERING_WORLD()
    end)
end

function Skin:PLAYER_ENTERING_WORLD()
    -- Wait for UI to fully load
    C_Timer.After(2, function()
        if not self.db or not self.db.profile then return end
        
        if self.db.profile.skinActionBars then
            self:SkinActionBarButtons()
        end
        
        if self.db.profile.skinTooltips then
            self:SkinTooltips()
        end
        
        if self.db.profile.skinChatFrames then
            self:SkinChatFrames()
        end
        
        if self.db.profile.skinUnitFrames then
            self:SkinUnitFrames()
        end
        
        if self.db.profile.skinBags then
            self:SkinBags()
        end
        
        if self.db.profile.skinBlizzardFrames then
            self:SkinBlizzardFrames()
        end
        
        -- Hook frame show events to skin frames as they appear
        self:SetupDynamicSkinning()
    end)
end

-- ============================================================================
-- DYNAMIC SKINNING HOOKS
-- ============================================================================

function Skin:SetupDynamicSkinning()
    if self.dynamicHooksSetup then return end
    
    -- Hook into frame creation to skin new frames
    local function SkinFrameOnShow(frame)
        if not frame.muiSkinned and Skin.db and Skin.db.profile.skinBlizzardFrames then
            Skin:ApplyFrameSkin(frame)
            frame.muiSkinned = true
        end
    end
    
    -- List of frame names to watch for
    local framesToWatch = {
        "CharacterFrame",
        "SpellBookFrame", 
        "ProfessionsFrame",
        "CollectionsJournal",
        "EncounterJournal",
        "AchievementFrame",
        "WorldMapFrame",
        "PVPUIFrame",
        "CommunitiesFrame",
        "PlayerChoiceFrame",
        "QuestFrame",
        "GossipFrame",
        "MerchantFrame",
        "MailFrame",
        "GameMenuFrame",
    }
    
    for _, frameName in ipairs(framesToWatch) do
        local frame = _G[frameName]
        if frame and frame.HookScript then
            frame:HookScript("OnShow", SkinFrameOnShow)
        end
    end
    
    self.dynamicHooksSetup = true
end

-- ============================================================================
-- CORE SKINNING FUNCTIONS
-- ============================================================================

--[[
    Applies skin to any frame with backdrop support
    @param frame - The frame to skin
    @param skinName - Optional specific skin name (defaults to globalSkin)
]]
function Skin:ApplyFrameSkin(frame, skinName)
    if not frame then return end
    if not frame.SetBackdrop and not frame.SetBackdropTemplate then return end
    
    -- Safety check: ensure database is initialized
    if not self.db or not self.db.profile then
        skinName = skinName or "Midnight"
    else
        skinName = skinName or self.db.profile.globalSkin
    end
    
    local skin = SKINS[skinName] or SKINS["Midnight"]
    
    -- Ensure frame has BackdropTemplate mixin
    if not frame.SetBackdrop and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
        frame:OnBackdropLoaded()
    end
    
    -- Apply backdrop directly to the frame
    if frame.SetBackdrop then
        frame:SetBackdrop(skin.backdrop)
        frame:SetBackdropColor(unpack(skin.bgColor))
        if skin.borderAlpha and skin.borderAlpha > 0 then
            frame:SetBackdropBorderColor(unpack(skin.borderColor))
        end
    end
end

--[[
    Gets the current skin configuration
    @param skinName - Optional specific skin name (defaults to globalSkin)
    @return skin table
]]
function Skin:GetSkin(skinName)
    -- Safety check: ensure database is initialized
    if not self.db or not self.db.profile then
        skinName = skinName or "Midnight"
    else
        skinName = skinName or self.db.profile.globalSkin
    end
    return SKINS[skinName] or SKINS["Midnight"]
end

-- ============================================================================
-- ACTION BAR BUTTON SKINNING
-- ============================================================================

function Skin:SkinActionBarButtons()
    local bgColor = self.db.profile.buttonBackgroundColor
    local borderColor = self.db.profile.buttonBorderColor
    
    -- Setup hooks only once - removed old hooks that don't exist in WoW 12.0
    if not self.hooksSetup then
        -- Instead of hooking non-existent functions, we'll just periodically check buttons
        -- This is less elegant but more reliable across WoW versions
        self.hooksSetup = true
    end
    
    -- Skin ALL existing action buttons with multiple attempts
    local function SkinAllButtons()
        local buttonsSkinned = 0
        
        for i = 1, 12 do
            local buttons = {
                _G["ActionButton"..i],
                _G["MultiBarBottomLeftButton"..i],
                _G["MultiBarBottomRightButton"..i],
                _G["MultiBarRightButton"..i],
                _G["MultiBarLeftButton"..i],
                _G["MultiBar5Button"..i],
                _G["MultiBar6Button"..i],
                _G["MultiBar7Button"..i]
            }
            
            for _, btn in ipairs(buttons) do
                if btn then
                    self:SkinButton(btn)
                    buttonsSkinned = buttonsSkinned + 1
                end
            end
        end
        
        -- Pet bar buttons
        for i = 1, 10 do
            local btn = _G["PetActionButton"..i]
            if btn then
                self:SkinButton(btn)
                buttonsSkinned = buttonsSkinned + 1
            end
            
            btn = _G["StanceButton"..i]
            if btn then
                self:SkinButton(btn)
                buttonsSkinned = buttonsSkinned + 1
            end
        end
    end
    
    -- Try immediately
    SkinAllButtons()
    
    -- Try again after 1 second in case buttons load late
    C_Timer.After(1, SkinAllButtons)
    
    -- Try one more time after 3 seconds
    C_Timer.After(3, SkinAllButtons)
    
    -- Set up a periodic check to maintain skins (every 5 seconds)
    if not self.skinMaintenanceTimer then
        self.skinMaintenanceTimer = C_Timer.NewTicker(5, function()
            if Skin.db and Skin.db.profile.skinActionBars then
                -- Silently maintain button skins
                for i = 1, 12 do
                    local buttons = {
                        _G["ActionButton"..i],
                        _G["MultiBarBottomLeftButton"..i],
                        _G["MultiBarBottomRightButton"..i],
                        _G["MultiBarRightButton"..i],
                        _G["MultiBarLeftButton"..i],
                        _G["MultiBar5Button"..i],
                        _G["MultiBar6Button"..i],
                        _G["MultiBar7Button"..i]
                    }
                    
                    for _, btn in ipairs(buttons) do
                        if btn and btn.muiSkinned then
                            Skin:MaintainButtonSkin(btn)
                        end
                    end
                end
            end
        end)
    end
end

function Skin:SkinButton(btn)
    -- Safety check: ensure database is initialized
    if not self.db or not self.db.profile then
        return
    end
    
    if not btn then 
        return 
    end
    
    if not self.db.profile.skinActionBars then 
        return 
    end
    
    local bgColor = self.db.profile.buttonBackgroundColor
    
    -- Create dark background
    if not btn.muiSkinBg then
        btn.muiSkinBg = btn:CreateTexture(nil, "BACKGROUND", nil, -8)
        btn.muiSkinBg:SetAllPoints(btn)
    end
    
    btn.muiSkinBg:Show()
    btn.muiSkinBg:SetDrawLayer("BACKGROUND", -8)
    btn.muiSkinBg:SetColorTexture(unpack(bgColor))
    
    -- Get icon texture
    local icon = btn.icon or btn.Icon
    if not icon then
        local btnName = btn:GetName()
        if btnName then
            icon = _G[btnName.."Icon"]
        end
    end
    
    -- Apply icon cropping
    if icon and icon.SetTexCoord then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetDrawLayer("ARTWORK", 1)
    end
    
    -- Hide Blizzard elements
    self:HideBlizzardButtonElements(btn)
    
    btn.muiSkinned = true
end

function Skin:MaintainButtonSkin(btn)
    if not btn or not btn.muiSkinned then return end
    
    if btn.muiSkinBg then
        btn.muiSkinBg:Show()
    end
    
    self:HideBlizzardButtonElements(btn)
end

function Skin:MaintainButtonSkin(btn)
    if not btn or not btn.muiSkinned then return end
    
    if btn.muiSkinBg then
        btn.muiSkinBg:SetDrawLayer("BACKGROUND", -8)
        btn.muiSkinBg:SetAlpha(1)
        btn.muiSkinBg:Show()
    end
    
    self:HideBlizzardButtonElements(btn)
end

function Skin:HideBlizzardButtonElements(btn)
    local elementsToHide = {
        "Border",
        "NormalTexture",
        "SlotBackground",
        "BorderSheen",
        "FloatingBG",
        "SlotArt",
        "CheckedTexture"
    }
    
    for _, elementName in ipairs(elementsToHide) do
        local element = btn[elementName]
        if element then
            if element.SetAlpha then element:SetAlpha(0) end
            if element.Hide then element:Hide() end
        end
    end
    
    local normalTexture = btn:GetNormalTexture()
    if normalTexture then
        normalTexture:SetAlpha(0)
        normalTexture:Hide()
    end
end

-- ============================================================================
-- TOOLTIP SKINNING
-- ============================================================================

function Skin:SkinTooltips()
    local tooltips = {
        GameTooltip,
        ItemRefTooltip,
        ShoppingTooltip1,
        ShoppingTooltip2,
        EmbeddedItemTooltip,
        RewardSmallTooltip
    }
    
    for _, tooltip in ipairs(tooltips) do
        if tooltip then
            self:ApplyFrameSkin(tooltip)
        end
    end
    
    -- Hook tooltip show to apply skin
    GameTooltip:HookScript("OnShow", function(self)
        Skin:ApplyFrameSkin(self)
    end)
end


-- ============================================================================
-- UNIT FRAME SKINNING
-- ============================================================================

function Skin:SkinUnitFrames()
    local unitFrames = {
        -- Player and target
        PlayerFrame,
        TargetFrame,
        TargetFrameToT,
        FocusFrame,
        FocusFrameToT,
        
        -- Pet frames
        PetFrame,
        
        -- Boss frames
        Boss1TargetFrame,
        Boss2TargetFrame,
        Boss3TargetFrame,
        Boss4TargetFrame,
        Boss5TargetFrame,
        
        -- Arena frames
        ArenaEnemyMatchFramesFrame,
    }
    
    for _, frame in ipairs(unitFrames) do
        if frame then
            self:ApplyFrameSkin(frame)
            
            -- Also skin the health and power bars if they exist
            if frame.healthBar then
                self:ApplyFrameSkin(frame.healthBar)
            end
            if frame.manabar then
                self:ApplyFrameSkin(frame.manabar)
            end
        end
    end
    
    -- Party frames
    if PartyFrame then
        for i = 1, 4 do
            local partyFrame = _G["PartyMemberFrame"..i]
            if partyFrame then
                self:ApplyFrameSkin(partyFrame)
            end
        end
    end
    
    -- Compact raid frames
    if CompactRaidFrameContainer then
        self:ApplyFrameSkin(CompactRaidFrameContainer)
    end
end

-- ============================================================================
-- BAG SKINNING
-- ============================================================================

function Skin:SkinBags()
    if not self.db or not self.db.profile or not self.db.profile.skinBags then return end
    
    -- WoW 12.0 Combined Bags
    C_Timer.After(0.5, function()
        if ContainerFrameCombinedBags and not ContainerFrameCombinedBags.muiSkinned then
            Skin:ApplyFrameSkin(ContainerFrameCombinedBags)
            ContainerFrameCombinedBags.muiSkinned = true
        end
        
        -- Individual bags (if user separates them)
        for i = 1, 13 do
            local bagFrame = _G["ContainerFrame"..i]
            if bagFrame and not bagFrame.muiSkinned then
                Skin:ApplyFrameSkin(bagFrame)
                bagFrame.muiSkinned = true
            end
        end
        
        -- Bank
        if BankFrame and not BankFrame.muiSkinned then
            Skin:ApplyFrameSkin(BankFrame)
            BankFrame.muiSkinned = true
        end
        
        -- Account Bank
        if AccountBankPanel and not AccountBankPanel.muiSkinned then
            Skin:ApplyFrameSkin(AccountBankPanel)
            AccountBankPanel.muiSkinned = true
        end
    end)
end

-- ============================================================================
-- BLIZZARD UI FRAMES SKINNING
-- ============================================================================
if not self.db or not self.db.profile or not self.db.profile.skinBlizzardFrames then return end
    
    -- Use WoW 12.0 API to find frames
    local function TrySkinFrame(frameName)
        local frame = _G[frameName]
        if frame and not frame.muiSkinned then
            Skin:ApplyFrameSkin(frame)
            frame.muiSkinned = true
        end
    end
    
    -- Character & Equipment
    TrySkinFrame("CharacterFrame")
    TrySkinFrame("PaperDollFrame")
    TrySkinFrame("ReputationFrame")
    TrySkinFrame("TokenFrame")
    
    -- Spellbook & Professions  
    TrySkinFrame("SpellBookFrame")
    TrySkinFrame("ProfessionsFrame")
    TrySkinFrame("ProfessionsCustomerOrdersFrame")
    
    -- Talents (War Within uses new system)
    TrySkinFrame("PlayerSpellsFrame")
    TrySkinFrame("ClassTalentFrame")
    
    -- Collections
    TrySkinFrame("CollectionsJournal")
    TrySkinFrame("MountJournal")
    TrySkinFrame("PetJournal")
    TrySkinFrame("ToyBox")
    TrySkinFrame("HeirloomsJournal")
    TrySkinFrame("WardrobeFrame")
    
    -- Adventure Guide & Achievements
    TrySkinFrame("EncounterJournal")
    TrySkinFrame("AchievementFrame")
    
    -- World Map (new in War Within)
    TrySkinFrame("WorldMapFrame")
    
    -- Social & Guild
    TrySkinFrame("FriendsFrame")
    TrySkinFrame("CommunitiesFrame")
    TrySkinFrame("GuildFrame")
    
    -- PvP & Group Finder
    TrySkinFrame("PVPUIFrame")
    TrySkinFrame("PVEFrame")
    TrySkinFrame("LFGDungeonReadyDialog")
    
    -- Quest & NPC Interaction
    TrySkinFrame("QuestFrame")
    TrySkinFrame("GossipFrame")
    TrySkinFrame("QuestLogPopupDetailFrame")
    TrySkinFrame("PlayerChoiceFrame")
    
    -- Trading & Services
    TrySkinFrame("MerchantFrame")
    TrySkinFrame("MailFrame")
    TrySkinFrame("TradeFrame")
    TrySkinFrame("AuctionHouseFrame")
    
    -- System
    TrySkinFrame("GameMenuFrame")
    TrySkinFrame("VideoOptionsFrame")
    TrySkinFrame("InterfaceOptionsFrame")
    TrySkinFrame("SettingsPanel")
    TrySkinFrame("AddonList")
    TrySkinFrame("KeyBindingFrame")
    TrySkinFrame("MacroFrame")
    
    -- Calendar & Help
    TrySkinFrame("CalendarFrame")
    TrySkinFrame("HelpFrame")
    
    -- Loot & Popups
    TrySkinFrame("LootFrame")
    TrySkinFrame("GroupLootFrame1")
    TrySkinFrame("StackSplitFrame")
    
    for i = 1, 4 do
        TrySkinFrame("StaticPopup"..i)
    end
end

-- ============================================================================
-- TOOLTIP SKINNING
-- ============================================================================

function Skin:SkinTooltips()
    local tooltips = {
        GameTooltip,
        ItemRefTooltip,
        ShoppingTooltip1,
        ShoppingTooltip2,
        EmbeddedItemTooltip,
    }
    
    for _, tooltip in ipairs(tooltips) do
        if tooltip and not tooltip.muiSkinned then
            self:ApplyFrameSkin(tooltip)
            tooltip.muiSkinned = true
        end
    end
end

-- ============================================================================
-- CHAT FRAME SKINNING
-- ============================================================================

function Skin:SkinChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then
            self:ApplyFrameSkin(frame)
        end
    end
end

-- ============================================================================
-- OPTIONS
-- ============================================================================

function Skin:GetOptions()
    local skinList = {}
    for name in pairs(SKINS) do
        skinList[name] = name
    end
    
    return {
        type = "group",
        name = "Skinning",
        order = 15,
        args = {
            header = {
                type = "header",
                name = "Global Skinning System",
                order = 1
            },
            desc = {
                type = "description",
                name = "Applies consistent visual styling across all MidnightUI elements.",
                order = 2
            },
            globalSkin = {
                name = "Global Skin",
                desc = "Default skin applied to all UI elements",
                type = "select",
                order = 3,
                values = skinList,
                get = function() return self.db.profile.globalSkin end,
                set = function(_, v)
                    self.db.profile.globalSkin = v
                    -- Trigger reskin of everything
                    C_UI.Reload()
                end
            },
            spacer1 = { type = "header", name = "Module-Specific Skinning", order = 10 },
            skinActionBars = {
                name = "Skin Action Bar Buttons",
                desc = "Apply dark background to action bar buttons",
                type = "toggle",
                order = 11,
                width = "full",
                get = function() return self.db.profile.skinActionBars end,
                set = function(_, v)
                    self.db.profile.skinActionBars = v
                    if v then
                        self:SkinActionBarButtons()
                    else
                        C_UI.Reload()
                    end
                end
            },
            skinUnitFrames = {
                name = "Skin Unit Frames (Experimental)",
                desc = "Apply skin to player, target, party, and raid frames. WARNING: May conflict with Blizzard unit frames. Disable if you experience errors.",
                type = "toggle",
                order = 12,
                width = "full",
                get = function() return self.db.profile.skinUnitFrames end,
                set = function(_, v)
                    self.db.profile.skinUnitFrames = v
                    C_UI.Reload()
                end
            },
            skinBags = {
                name = "Skin Bags",
                desc = "Apply skin to bags and bank frames",
                type = "toggle",
                order = 13,
                width = "full",
                get = function() return self.db.profile.skinBags end,
                set = function(_, v)
                    self.db.profile.skinBags = v
                    if v then
                        self:SkinBags()
                    else
                        C_UI.Reload()
                    end
                end
            },
            skinBlizzardFrames = {
                name = "Skin Blizzard UI Frames",
                desc = "Apply skin to character panel, spellbook, talents, collections, etc.",
                type = "toggle",
                order = 14,
                width = "full",
                get = function() return self.db.profile.skinBlizzardFrames end,
                set = function(_, v)
                    self.db.profile.skinBlizzardFrames = v
                    if v then
                        self:SkinBlizzardFrames()
                    else
                        C_UI.Reload()
                    end
                end
            },
            skinTooltips = {
                name = "Skin Tooltips",
                desc = "Apply skin to game tooltips",
                type = "toggle",
                order = 15,
                width = "full",
                get = function() return self.db.profile.skinTooltips end,
                set = function(_, v)
                    self.db.profile.skinTooltips = v
                    if v then
                        self:SkinTooltips()
                    end
                end
            },
            skinChatFrames = {
                name = "Skin Chat Frames",
                desc = "Apply skin to chat windows",
                type = "toggle",
                order = 16,
                width = "full",
                get = function() return self.db.profile.skinChatFrames end,
                set = function(_, v)
                    self.db.profile.skinChatFrames = v
                    C_UI.Reload()
                end
            },
            spacer2 = { type = "header", name = "Button Styling", order = 20 },
            buttonBackgroundColor = {
                name = "Button Background Color",
                desc = "Background color for action bar buttons",
                type = "color",
                hasAlpha = true,
                order = 21,
                get = function()
                    local c = self.db.profile.buttonBackgroundColor
                    return c[1], c[2], c[3], c[4]
                end,
                set = function(_, r, g, b, a)
                    self.db.profile.buttonBackgroundColor = {r, g, b, a}
                    self:SkinActionBarButtons()
                end
            },
            buttonBorderColor = {
                name = "Button Border Color",
                desc = "Border color for action bar buttons",
                type = "color",
                hasAlpha = true,
                order = 22,
                get = function()
                    local c = self.db.profile.buttonBorderColor
                    return c[1], c[2], c[3], c[4]
                end,
                set = function(_, r, g, b, a)
                    self.db.profile.buttonBorderColor = {r, g, b, a}
                    self:SkinActionBarButtons()
                end
            }
        }
    }
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Export skin definitions for other modules
MidnightUI.Skins = SKINS

-- Export skinning function for other modules to use
function MidnightUI:SkinFrame(frame, skinName)
    if Skin and Skin.ApplyFrameSkin then
        Skin:ApplyFrameSkin(frame, skinName)
    end
end

function MidnightUI:GetSkin(skinName)
    if Skin and Skin.GetSkin then
        return Skin:GetSkin(skinName)
    end
    return SKINS["Midnight"]
end

return Skin