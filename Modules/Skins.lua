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
    -- DISABLED - Action bar skinning disabled
    return
    
    -- Wait for UI to fully load
    C_Timer.After(2, function()
        if not self.db or not self.db.profile then return end
        
        -- DISABLED - Removed all skinning calls
        
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
    
    -- Hook into frame show events to skin frames as they appear
    local function SkinFrameOnShow(frame)
        if not frame.muiSkinned and Skin.db and Skin.db.profile.skinBlizzardFrames then
            Skin:ApplyFrameSkin(frame)
            frame.muiSkinned = true
        end
    end
    
    -- List of frame names to watch for - these frames are created on-demand
    local framesToWatch = {
        "CharacterFrame",
        "SpellBookFrame",
        "PlayerSpellsFrame",
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
        "TradeFrame",
        "AuctionHouseFrame",
    }
    
    -- Hook existing frames
    for _, frameName in ipairs(framesToWatch) do
        local frame = _G[frameName]
        if frame and frame.HookScript then
            frame:HookScript("OnShow", SkinFrameOnShow)
        end
    end
    
    -- Use hooksecurefunc to catch frames as they're created
    hooksecurefunc("ShowUIPanel", function(frame)
        if frame and not frame.muiSkinned and Skin.db and Skin.db.profile.skinBlizzardFrames then
            Skin:ApplyFrameSkin(frame)
            frame.muiSkinned = true
        end
    end)
    
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
--[[
    Applies modern dark skin to a frame - strips Blizzard art and replaces with clean backdrop
    @param frame - The frame to skin
    @param skinName - Optional specific skin name (defaults to globalSkin)
]]
function Skin:ApplyFrameSkin(frame, skinName)
    if not frame then return end
    
    -- Safety check: ensure database is initialized
    if not self.db or not self.db.profile then
        skinName = skinName or "Midnight"
    else
        skinName = skinName or self.db.profile.globalSkin
    end
    
    local skin = SKINS[skinName] or SKINS["Midnight"]
    
    -- Strip all Blizzard decorative textures FIRST
    self:StripBlizzardTextures(frame)
    
    -- Ensure frame has BackdropTemplate mixin
    if not frame.SetBackdrop then
        if BackdropTemplateMixin then
            Mixin(frame, BackdropTemplateMixin)
            if frame.OnBackdropLoaded then
                frame:OnBackdropLoaded()
            end
        else
            return
        end
    end
    
    -- Verify SetBackdrop is now available
    if not frame.SetBackdrop then
        return
    end
    
    -- Apply clean modern backdrop with higher draw layer
    frame:SetBackdrop(skin.backdrop)
    frame:SetBackdropColor(unpack(skin.bgColor))
    
    if skin.borderAlpha and skin.borderAlpha > 0 then
        frame:SetBackdropBorderColor(unpack(skin.borderColor))
    end
    
    -- Force backdrop to show
    if frame.SetBackdropColor then
        frame:SetBackdropColor(unpack(skin.bgColor))
    end
    
    -- Skin the close button
    if frame.CloseButton then
        self:SkinCloseButton(frame.CloseButton)
    end
    
    -- Skin child frames AFTER applying backdrop
    self:SkinChildFrames(frame)
end

--[[
    Strips all Blizzard decorative textures from a frame
]]
function Skin:StripBlizzardTextures(frame)
    if not frame then return end
    
    -- Strip all draw layers first
    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region.GetObjectType then
            local success, objType = pcall(function() return region:GetObjectType() end)
            if success and objType == "Texture" then
                local drawLayer = region:GetDrawLayer()
                if drawLayer == "BACKGROUND" or drawLayer == "BORDER" or drawLayer == "ARTWORK" then
                    region:SetTexture(nil)
                    region:SetAlpha(0)
                    region:Hide()
                end
            end
        end
    end
    
    -- Hide NineSlice (WoW 12.0 border system)
    if frame.NineSlice then
        frame.NineSlice:SetAlpha(0)
        frame.NineSlice:Hide()
        -- Hide all NineSlice pieces
        if frame.NineSlice.TopEdge then frame.NineSlice.TopEdge:Hide() end
        if frame.NineSlice.BottomEdge then frame.NineSlice.BottomEdge:Hide() end
        if frame.NineSlice.LeftEdge then frame.NineSlice.LeftEdge:Hide() end
        if frame.NineSlice.RightEdge then frame.NineSlice.RightEdge:Hide() end
        if frame.NineSlice.TopLeftCorner then frame.NineSlice.TopLeftCorner:Hide() end
        if frame.NineSlice.TopRightCorner then frame.NineSlice.TopRightCorner:Hide() end
        if frame.NineSlice.BottomLeftCorner then frame.NineSlice.BottomLeftCorner:Hide() end
        if frame.NineSlice.BottomRightCorner then frame.NineSlice.BottomRightCorner:Hide() end
        if frame.NineSlice.Center then frame.NineSlice.Center:Hide() end
    end
    
    -- Hide Portrait Container and all its children
    if frame.PortraitContainer then
        frame.PortraitContainer:SetAlpha(0)
        frame.PortraitContainer:Hide()
        if frame.PortraitContainer.portrait then frame.PortraitContainer.portrait:Hide() end
        if frame.PortraitContainer.Portrait then frame.PortraitContainer.Portrait:Hide() end
        if frame.PortraitContainer.CircleMask then frame.PortraitContainer.CircleMask:Hide() end
        if frame.PortraitContainer.PortraitRing then frame.PortraitContainer.PortraitRing:Hide() end
    end
    
    -- Hide Portrait (legacy)
    if frame.portrait then
        frame.portrait:SetAlpha(0)
        frame.portrait:Hide()
    end
    if frame.Portrait then
        frame.Portrait:SetAlpha(0)
        frame.Portrait:Hide()
    end
    if frame.PortraitFrame then
        frame.PortraitFrame:SetAlpha(0)
        frame.PortraitFrame:Hide()
    end
    
    -- Hide Title Container but preserve text
    if frame.TitleContainer then
        if frame.TitleContainer.TitleText then
            local titleText = frame.TitleContainer.TitleText
            titleText:SetParent(frame)
            titleText:ClearAllPoints()
            titleText:SetPoint("TOP", frame, "TOP", 0, -8)
        end
        frame.TitleContainer:SetAlpha(0)
    end
    
    -- Hide all background textures
    local bgTextures = {
        "Bg", "BG", "bg", "Background", "BGTexture",
        "TopTileStreaks", "TitleBg", "DialogBG", "BorderFrame"
    }
    for _, bgName in ipairs(bgTextures) do
        if frame[bgName] then
            frame[bgName]:SetAlpha(0)
            frame[bgName]:Hide()
        end
    end
    
    -- Hide model background pieces
    for _, corner in ipairs({"TopLeft", "TopRight", "BotLeft", "BotRight", "Top", "Bottom", "Left", "Right"}) do
        local bg = frame["Background"..corner]
        if bg then
            bg:SetAlpha(0)
            bg:Hide()
        end
    end
    
    -- Hide all edge textures
    local edgeTextures = {
        "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
        "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
        "Center", "TopLeft", "TopRight", "BotLeft", "BotRight",
        "TopMiddle", "BottomMiddle", "LeftMiddle", "RightMiddle"
    }
    
    for _, texName in ipairs(edgeTextures) do
        if frame[texName] then
            frame[texName]:SetAlpha(0)
            frame[texName]:Hide()
        end
    end
    
    -- Hide Inset and its components (very common in Blizzard frames)
    if frame.Inset then
        if frame.Inset.Bg then
            frame.Inset.Bg:SetAlpha(0)
            frame.Inset.Bg:Hide()
        end
        if frame.Inset.NineSlice then
            frame.Inset.NineSlice:SetAlpha(0)
            frame.Inset.NineSlice:Hide()
            -- Hide NineSlice pieces in Inset
            if frame.Inset.NineSlice.TopEdge then frame.Inset.NineSlice.TopEdge:Hide() end
            if frame.Inset.NineSlice.BottomEdge then frame.Inset.NineSlice.BottomEdge:Hide() end
            if frame.Inset.NineSlice.LeftEdge then frame.Inset.NineSlice.LeftEdge:Hide() end
            if frame.Inset.NineSlice.RightEdge then frame.Inset.NineSlice.RightEdge:Hide() end
            if frame.Inset.NineSlice.TopLeftCorner then frame.Inset.NineSlice.TopLeftCorner:Hide() end
            if frame.Inset.NineSlice.TopRightCorner then frame.Inset.NineSlice.TopRightCorner:Hide() end
            if frame.Inset.NineSlice.BottomLeftCorner then frame.Inset.NineSlice.BottomLeftCorner:Hide() end
            if frame.Inset.NineSlice.BottomRightCorner then frame.Inset.NineSlice.BottomRightCorner:Hide() end
        end
        -- Strip Inset borders
        for _, edge in ipairs({"Top", "Bottom", "Left", "Right", "TopLeft", "TopRight", "BottomLeft", "BottomRight"}) do
            if frame.Inset[edge] then
                frame.Inset[edge]:SetAlpha(0)
                frame.Inset[edge]:Hide()
            end
        end
    end
    
    -- Hide InsetFrame if it exists separately
    if frame.InsetFrame then
        frame.InsetFrame:SetAlpha(0)
    end
    
    -- Hide various border elements
    local borderElements = {
        "TopLeftTexture", "TopRightTexture", "BottomLeftTexture", "BottomRightTexture",
        "TopTexture", "BottomTexture", "LeftTexture", "RightTexture",
        "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
        "TopBorder", "BottomBorder", "LeftBorder", "RightBorder",
        "BorderLeft", "BorderRight", "BorderTop", "BorderBottom",
        "_TopLeft", "_TopRight", "_BottomLeft", "_BottomRight",
        "_Left", "_Right", "_Top", "_Bottom"
    }
    
    for _, borderName in ipairs(borderElements) do
        if frame[borderName] then
            frame[borderName]:SetAlpha(0)
            frame[borderName]:Hide()
        end
    end
    
    -- Hide overlay textures
    if frame.Overlay then
        frame.Overlay:SetAlpha(0)
        frame.Overlay:Hide()
    end
    
    -- Hide all textures by scanning regions
    for _, region in pairs({frame:GetRegions()}) do
        if region and region.GetObjectType then
            local success, objType = pcall(function() return region:GetObjectType() end)
            if success and objType == "Texture" then
                local texturePath = region.GetTexture and region:GetTexture()
                if texturePath then
                    local path = tostring(texturePath):lower()
                    -- Very aggressive - hide almost all Interface art
                    if path:find("interface") then
                        local shouldHide = path:find("frame") or 
                            path:find("border") or
                            path:find("portrait") or
                            path:find("corner") or
                            path:find("parchment") or
                            path:find("characterframe") or
                            path:find("paperdoll") or
                            path:find("questframe") or
                            path:find("gossip") or
                            path:find("merchant") or
                            path:find("mail") or
                            path:find("dialog") or
                            path:find("auctionfra") or
                            path:find("bankframe") or
                            path:find("friendsframe") or
                            path:find("guildframe") or
                            path:find("pvp") or
                            path:find("spellbook") or
                            path:find("talent") or
                            path:find("achievement") or
                            path:find("collections") or
                            path:find("encounter") or
                            path:find("tradeskill") or
                            path:find("profession") or
                            path:find("tooltip") or
                            path:find("raidboss") or
                            path:find("calendar") or
                            path:find("lfg") or
                            path:find("trade") or
                            path:find("loot") or
                            path:find("taxiframe") or
                            path:find("petition") or
                            path:find("tabard") or
                            path:find("barbershop") or
                            path:find("itemupgrade") or
                            path:find("transmogrify") or
                            path:find("voidstorage") or
                            path:find("blackmarket") or
                            path:find("ui-background") or
                            path:find("ui-frame") or
                            path:find("divider")
                        
                        if shouldHide then
                            region:SetTexture(nil)
                            region:SetAlpha(0)
                            region:Hide()
                        end
                    end
                end
            end
        end
    end
end

--[[
    Skins child frames like buttons, tabs, scrollbars
]]
function Skin:SkinChildFrames(frame)
    if not frame then return end
    
    -- Skin all child buttons
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        if child then
            -- Use pcall to safely get object type (some virtual frames don't have this method)
            local success, objType = pcall(function() return child:GetObjectType() end)
            if success and objType then
                if objType == "Button" then
                    self:SkinFrameButton(child)
                elseif objType == "CheckButton" then
                    self:SkinCheckButton(child)
                elseif objType == "Frame" and child.GetScrollChild then
                    -- Scrollframe
                    self:SkinScrollFrame(child)
                end
            end
        end
    end
    
    -- Skin tabs
    local frameName = frame:GetName()
    if frameName then
        for i = 1, 10 do
            local tab = _G[frameName.."Tab"..i]
            if tab then
                self:SkinTab(tab)
            else
                break
            end
        end
    end
end

--[[
    Skins a close button
]]
function Skin:SkinCloseButton(btn)
    if not btn or btn.muiCloseSkinned then return end
    
    -- Completely strip the button textures
    for i = 1, btn:GetNumRegions() do
        local region = select(i, btn:GetRegions())
        if region and region.GetObjectType then
            local success, objType = pcall(function() return region:GetObjectType() end)
            if success and objType == "Texture" then
                region:SetTexture(nil)
                region:Hide()
            end
        end
    end
    
    -- Hide all button textures
    if btn.SetNormalTexture then btn:SetNormalTexture("") end
    if btn.SetPushedTexture then btn:SetPushedTexture("") end
    if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
    if btn.SetDisabledTexture then btn:SetDisabledTexture("") end
    
    -- Size the button
    btn:SetSize(20, 20)
    
    -- Create dark background
    if BackdropTemplateMixin and not btn.SetBackdrop then
        Mixin(btn, BackdropTemplateMixin)
        if btn.OnBackdropLoaded then
            btn:OnBackdropLoaded()
        end
    end
    
    if btn.SetBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0.2, 0.2, 0.2, 1)
        btn:SetBackdropBorderColor(0, 0, 0, 1)
    end
    
    -- Create custom X text
    if not btn.customX then
        btn.customX = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        btn.customX:SetPoint("CENTER", 0, 0)
        btn.customX:SetText("×")
        btn.customX:SetTextColor(0.8, 0.2, 0.2, 1)
        btn.customX:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    end
    
    -- Hover effect
    btn:HookScript("OnEnter", function(self)
        if self.customX then
            self.customX:SetTextColor(1, 0, 0, 1)
        end
        if self.SetBackdropColor then
            self:SetBackdropColor(0.3, 0.1, 0.1, 1)
        end
    end)
    
    btn:HookScript("OnLeave", function(self)
        if self.customX then
            self.customX:SetTextColor(0.8, 0.2, 0.2, 1)
        end
        if self.SetBackdropColor then
            self:SetBackdropColor(0.2, 0.2, 0.2, 1)
        end
    end)
    
    btn.muiCloseSkinned = true
end

--[[
    Skins a regular button
]]
function Skin:SkinFrameButton(btn)
    if not btn or btn.muiButtonSkinned then return end
    
    -- Strip Blizzard textures
    if btn.Left then btn.Left:SetAlpha(0) end
    if btn.Right then btn.Right:SetAlpha(0) end
    if btn.Middle then btn.Middle:SetAlpha(0) end
    if btn.SetNormalTexture then btn:SetNormalTexture("") end
    if btn.SetPushedTexture then btn:SetPushedTexture("") end
    if btn.SetDisabledTexture then btn:SetDisabledTexture("") end
    
    -- Add backdrop
    if BackdropTemplateMixin and not btn.SetBackdrop then
        Mixin(btn, BackdropTemplateMixin)
        if btn.OnBackdropLoaded then
            btn:OnBackdropLoaded()
        end
    end
    
    if btn.SetBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        btn:SetBackdropColor(0.2, 0.2, 0.2, 1)
        btn:SetBackdropBorderColor(0, 0, 0, 1)
        
        -- Hover effect
        btn:HookScript("OnEnter", function(self)
            self:SetBackdropColor(0.3, 0.3, 0.3, 1)
        end)
        btn:HookScript("OnLeave", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 1)
        end)
    end
    
    btn.muiButtonSkinned = true
end

--[[
    Skins a checkbox
]]
function Skin:SkinCheckButton(check)
    if not check or check.muiCheckSkinned then return end
    
    -- Hide default checkbox texture
    if check.SetNormalTexture then check:SetNormalTexture("") end
    if check.SetPushedTexture then check:SetPushedTexture("") end
    if check.SetHighlightTexture then check:SetHighlightTexture("") end
    if check.SetCheckedTexture then check:SetCheckedTexture("") end
    if check.SetDisabledCheckedTexture then check:SetDisabledCheckedTexture("") end
    
    -- Create modern checkbox
    if BackdropTemplateMixin and not check.SetBackdrop then
        Mixin(check, BackdropTemplateMixin)
        if check.OnBackdropLoaded then
            check:OnBackdropLoaded()
        end
    end
    
    if check.SetBackdrop then
        check:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        check:SetBackdropColor(0.1, 0.1, 0.1, 1)
        check:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        -- Custom checkmark
        if not check.muiCheck then
            check.muiCheck = check:CreateTexture(nil, "OVERLAY")
            check.muiCheck:SetTexture("Interface\\Buttons\\WHITE8X8")
            check.muiCheck:SetPoint("TOPLEFT", 3, -3)
            check.muiCheck:SetPoint("BOTTOMRIGHT", -3, 3)
            check.muiCheck:SetVertexColor(0, 1, 0, 1)
        end
        
        check:HookScript("OnClick", function(self)
            if self:GetChecked() then
                self.muiCheck:Show()
            else
                self.muiCheck:Hide()
            end
        end)
        
        -- Initial state
        if check:GetChecked() then
            check.muiCheck:Show()
        else
            check.muiCheck:Hide()
        end
    end
    
    check.muiCheckSkinned = true
end

--[[
    Skins a scrollframe
]]
function Skin:SkinScrollFrame(scroll)
    if not scroll or scroll.muiScrollSkinned then return end
    
    -- Skin scrollbar
    local scrollbar = scroll.ScrollBar or scroll.scrollBar
    if scrollbar then
        -- Hide default textures
        if scrollbar.Background then scrollbar.Background:Hide() end
        if scrollbar.Top then scrollbar.Top:Hide() end
        if scrollbar.Bottom then scrollbar.Bottom:Hide() end
        if scrollbar.Middle then scrollbar.Middle:Hide() end
        
        -- Skin thumb
        local thumb = scrollbar.ThumbTexture or scrollbar.thumbTexture
        if thumb then
            thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
            thumb:SetVertexColor(0.3, 0.3, 0.3, 1)
        end
        
        -- Skin buttons
        if scrollbar.ScrollUpButton then
            self:SkinFrameButton(scrollbar.ScrollUpButton)
        end
        if scrollbar.ScrollDownButton then
            self:SkinFrameButton(scrollbar.ScrollDownButton)
        end
    end
    
    scroll.muiScrollSkinned = true
end

--[[
    Skins a tab button
]]
function Skin:SkinTab(tab)
    if not tab or tab.muiTabSkinned then return end
    
    -- Hide default textures
    if tab.Left then tab.Left:SetAlpha(0) end
    if tab.Right then tab.Right:SetAlpha(0) end
    if tab.Middle then tab.Middle:SetAlpha(0) end
    if tab.LeftDisabled then tab.LeftDisabled:SetAlpha(0) end
    if tab.RightDisabled then tab.RightDisabled:SetAlpha(0) end
    if tab.MiddleDisabled then tab.MiddleDisabled:SetAlpha(0) end
    if tab.LeftHighlight then tab.LeftHighlight:SetAlpha(0) end
    if tab.RightHighlight then tab.RightHighlight:SetAlpha(0) end
    if tab.MiddleHighlight then tab.MiddleHighlight:SetAlpha(0) end
    
    -- Create modern tab backdrop
    if BackdropTemplateMixin and not tab.SetBackdrop then
        Mixin(tab, BackdropTemplateMixin)
        if tab.OnBackdropLoaded then
            tab:OnBackdropLoaded()
        end
    end
    
    if tab.SetBackdrop then
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        
        -- Update colors based on selection
        local function UpdateTabColor()
            if tab:GetID() == PanelTemplates_GetSelectedTab(tab:GetParent()) then
                tab:SetBackdropColor(0.2, 0.2, 0.2, 1)
                tab:SetBackdropBorderColor(0, 1, 0, 1)
            else
                tab:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
                tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            end
        end
        
        tab:HookScript("OnShow", UpdateTabColor)
        tab:HookScript("OnClick", UpdateTabColor)
        UpdateTabColor()
    end
    
    tab.muiTabSkinned = true
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

--[[
function Skin:SkinActionBarButtons()
    -- DISABLED - Action bar skinning completely disabled
    print("|cffff0000MidnightUI:|r Action bar skinning is currently disabled.")
    return
end

function Skin:SkinButton(btn)
    -- DISABLED - Button skinning completely disabled
    return
end

function Skin:MaintainButtonSkin(btn)
    -- DISABLED - Button skin maintenance completely disabled
    return
end

function Skin:HideBlizzardButtonElements(btn)
    -- DISABLED - Blizzard element hiding completely disabled
    return
end
]]--

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

function Skin:SkinBlizzardFrames()
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
    TrySkinFrame("PlayerSpellsFrame")
    TrySkinFrame("ProfessionsFrame")
    
    -- Collections
    TrySkinFrame("CollectionsJournal")
    TrySkinFrame("MountJournal")
    TrySkinFrame("PetJournal")
    TrySkinFrame("ToyBox")
    TrySkinFrame("WardrobeFrame")
    
    -- Achievements & Encounters
    TrySkinFrame("AchievementFrame")
    TrySkinFrame("EncounterJournal")
    
    -- Social
    TrySkinFrame("FriendsFrame")
    TrySkinFrame("CommunitiesFrame")
    TrySkinFrame("GuildFrame")
    
    -- PvP
    TrySkinFrame("PVPUIFrame")
    TrySkinFrame("PVEFrame")
    
    -- Quest & NPC
    TrySkinFrame("QuestFrame")
    TrySkinFrame("GossipFrame")
    TrySkinFrame("PlayerChoiceFrame")
    
    -- Trading
    TrySkinFrame("MerchantFrame")
    TrySkinFrame("MailFrame")
    TrySkinFrame("TradeFrame")
    
    -- System
    TrySkinFrame("GameMenuFrame")
    TrySkinFrame("SettingsPanel")
    TrySkinFrame("AddonList")
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