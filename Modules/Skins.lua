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
    print("|cff00ff00[Skins]|r OnInitialize called")
    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
end

function Skin:OnDBReady()
    print("|cff00ff00[Skins]|r OnDBReady called")
    self.db = MidnightUI.db:RegisterNamespace("Skin", {
        profile = {
            globalSkin = "Midnight",
            skinActionBars = true,
            skinDataBrokerBars = true,
            skinUIButtons = true,
            skinMinimap = true,
            skinTooltips = true,
            skinChatFrames = false,
            buttonBackgroundColor = {0.1, 0.1, 0.1, 0.8},
            buttonBorderColor = {0, 0, 0, 1}
        }
    })
    
    print("|cff00ff00[Skins]|r Database initialized")
    print("|cff00ff00[Skins]|r skinActionBars setting:", self.db.profile.skinActionBars)
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    print("|cff00ff00[Skins]|r Registered for PLAYER_ENTERING_WORLD")
    
    -- Immediately trigger skinning since we may have already entered world
    C_Timer.After(0.1, function()
        print("|cff00ff00[Skins]|r Manually triggering PLAYER_ENTERING_WORLD handler")
        self:PLAYER_ENTERING_WORLD()
    end)
end

function Skin:PLAYER_ENTERING_WORLD()
    print("|cff00ff00[Skins]|r PLAYER_ENTERING_WORLD fired")
    -- Wait longer to ensure ActionBars module has created all buttons
    C_Timer.After(1.5, function()
        if self.db.profile.skinActionBars then
            self:SkinActionBarButtons()
        end
        
        if self.db.profile.skinTooltips then
            self:SkinTooltips()
        end
        
        if self.db.profile.skinChatFrames then
            self:SkinChatFrames()
        end
    end)
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
    
    -- Safety check: ensure database is initialized
    if not self.db or not self.db.profile then
        print("|cffff0000[Skins]|r ApplyFrameSkin called before database initialized!")
        skinName = skinName or "Midnight"
    else
        skinName = skinName or self.db.profile.globalSkin
    end
    
    local skin = SKINS[skinName] or SKINS["Midnight"]
    
    -- Create backdrop frame if it doesn't exist
    if not frame.muiBackdrop then
        frame.muiBackdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.muiBackdrop:SetAllPoints()
        
        local level = frame:GetFrameLevel()
        frame.muiBackdrop:SetFrameLevel(level > 0 and level - 1 or 0)
    end
    
    -- Apply backdrop
    frame.muiBackdrop:SetBackdrop(skin.backdrop)
    frame.muiBackdrop:SetBackdropColor(unpack(skin.bgColor))
    frame.muiBackdrop:SetBackdropBorderColor(unpack(skin.borderColor))
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
        print("|cff00ff00[Skins]|r Setting up button update detection...")
        
        -- Instead of hooking non-existent functions, we'll just periodically check buttons
        -- This is less elegant but more reliable across WoW versions
        
        self.hooksSetup = true
        print("|cff00ff00[Skins]|r Hooks setup complete (using periodic check)")
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
        
        if buttonsSkinned > 0 then
            print("|cff00ff00MidnightUI Skins:|r Skinned " .. buttonsSkinned .. " action bar buttons")
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
        print("|cffff0000[Skins Debug]|r SkinButton called before database initialized!")
        return
    end
    
    if not btn then 
        print("|cffff0000[Skins Debug]|r SkinButton called with nil button")
        return 
    end
    
    if not self.db.profile.skinActionBars then 
        print("|cffff0000[Skins Debug]|r skinActionBars is disabled")
        return 
    end
    
    print("|cffff9900[Skins Debug]|r Skinning button:", btn:GetName())
    
    local bgColor = self.db.profile.buttonBackgroundColor
    
    -- Create dark background
    if not btn.muiSkinBg then
        print("|cffff9900[Skins Debug]|r Creating muiSkinBg for:", btn:GetName())
        btn.muiSkinBg = btn:CreateTexture(nil, "BACKGROUND", nil, -8)
        btn.muiSkinBg:SetAllPoints(btn)
    else
        print("|cffff9900[Skins Debug]|r muiSkinBg already exists for:", btn:GetName())
    end
    
    btn.muiSkinBg:Show()
    btn.muiSkinBg:SetDrawLayer("BACKGROUND", -8)
    btn.muiSkinBg:SetColorTexture(unpack(bgColor))
    
    print("|cff00ff00[Skins Debug]|r Background texture set for:", btn:GetName(), "Color:", bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    
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
        print("|cff00ff00[Skins Debug]|r Icon cropped for:", btn:GetName())
    else
        print("|cffff0000[Skins Debug]|r No icon found for:", btn:GetName())
    end
    
    -- Hide Blizzard elements
    self:HideBlizzardButtonElements(btn)
    
    btn.muiSkinned = true
    print("|cff00ff00[Skins Debug]|r Button fully skinned:", btn:GetName())
end

function Skin:MaintainButtonSkin(btn)
    if not btn or not btn.muiSkinned then return end
    
    if btn.muiSkinBg then
        btn.muiSkinBg:Show()
    end
    
    self:HideBlizzardButtonElements(btn)
end

function Skin:HideBlizzetDrawLayer("BACKGROUND", -8)
        btn.muiSkinBg:SetAlpha(1)
        btn.muiSkinBg:SardButtonElements(btn)
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
                    end
                end
            },
            skinTooltips = {
                name = "Skin Tooltips",
                desc = "Apply skin to game tooltips",
                type = "toggle",
                order = 12,
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
                order = 13,
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