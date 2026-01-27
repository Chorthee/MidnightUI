local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UF = MidnightUI:NewModule("UnitFrames", "AceEvent-3.0")

function UF:OnInitialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function UF:PLAYER_ENTERING_WORLD()
    if not MidnightUI.db.profile.modules.unitframes then return end
    
    self:SkinFrame(PlayerFrame)
    self:SkinFrame(PetFrame)
    self:SkinFrame(TargetFrame)
    self:SkinFrame(FocusFrame)
end

function UF:PLAYER_TARGET_CHANGED()
    if TargetFrame and TargetFrame:IsShown() then
        self:SkinFrame(TargetFrame)
        self:SkinFrame(TargetFrameToT)
    end
end

function UF:SkinFrame(frame)
    if not frame then return end
    
    -- 1. Apply Midnight Skin
    MidnightUI:SkinFrame(frame)
    
    -- 2. Customize Health Bars (Flat Texture)
    if frame.healthbar then
        frame.healthbar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        
        -- Use Class Colors if available
        local unit = frame.unit
        if unit and UnitIsPlayer(unit) then
            local _, class = UnitClass(unit)
            local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
            if c then
                frame.healthbar:SetStatusBarColor(c.r, c.g, c.b)
            end
        end
    end
    
    -- 3. Hide Blizzard Art (Modern API safe approach)
    -- We don't remove textures to avoid taints, we just set alpha to 0
    if frame.TextureFrame then
        frame.TextureFrame:SetAlpha(0)
    end
    
    -- Specific handling for PlayerFrame's circular portrait
    if frame == PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContainer then
        -- Hooking into the container to hide the default frame ring
        local container = PlayerFrame.PlayerFrameContent.PlayerFrameContainer
        if container.FrameTexture then container.FrameTexture:SetAlpha(0) end
    end
end