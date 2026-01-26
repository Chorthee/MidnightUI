local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local AB = MidnightUI:NewModule("ActionBars", "AceEvent-3.0")

function AB:OnInitialize()
    if not MidnightUI.db.profile.modules.actionbars then return end
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function AB:PLAYER_ENTERING_WORLD()
    -- 1. Hide Gryphons / Art
    if MainMenuBar then
        if MainMenuBar.ArtFrame then
            MainMenuBar.ArtFrame:SetAlpha(0)
            if MainMenuBar.ArtFrame.LeftEndCap then MainMenuBar.ArtFrame.LeftEndCap:Hide() end
            if MainMenuBar.ArtFrame.RightEndCap then MainMenuBar.ArtFrame.RightEndCap:Hide() end
            if MainMenuBar.ArtFrame.Background then MainMenuBar.ArtFrame.Background:Hide() end
        end
    end
    
    -- 2. Skin the Status Bars (XP / Rep)
    if StatusTrackingBarManager then
        MidnightUI:SkinFrame(StatusTrackingBarManager)
    end

    -- 3. Skin Buttons
    self:SkinButtons()
end

function AB:SkinButtons()
    -- FIX: Use the Mixin instead of the removed "ActionButton_Update" global
    if ActionBarActionButtonMixin and ActionBarActionButtonMixin.Update then
        hooksecurefunc(ActionBarActionButtonMixin, "Update", function(self)
            AB:ApplyButtonSkin(self)
        end)
    end
end

function AB:ApplyButtonSkin(button)
    if not button or button.muiSkinned then return end

    -- Create a dark backdrop behind the icon
    if not button.muiBg then
        button.muiBg = button:CreateTexture(nil, "BACKGROUND")
        button.muiBg:SetAllPoints(button)
        button.muiBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    end
    
    -- Trim the icon edges (Square look)
    -- Modern buttons typically have .icon key directly
    local icon = button.icon or _G[button:GetName() .. "Icon"]
    if icon then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    
    -- Hide the default border / textures
    if button.Border then button.Border:SetAlpha(0) end
    if button.NormalTexture then button.NormalTexture:SetAlpha(0) end
    
    -- Hide modern slot backgrounds if they exist
    if button.SlotBackground then button.SlotBackground:SetAlpha(0) end

    button.muiSkinned = true
end