local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UF = MidnightUI:NewModule("UnitFrames", "AceEvent-3.0")

function UF:OnInitialize()
    self:RegisterMessage("MIDNIGHTUI_DB_READY", "OnDBReady")
end

function UF:OnDBReady()
    if not MidnightUI.db.profile.modules.unitframes then 
        self:Disable()
        return 
    end
    
    self.db = MidnightUI.db:RegisterNamespace("UnitFrames", defaults)
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
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
    
    -- Blizzard art restoration: do not hide or set alpha to Blizzard art/textures
    -- All Blizzard art and textures are preserved
end