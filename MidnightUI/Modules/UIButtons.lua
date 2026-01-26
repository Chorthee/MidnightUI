local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local Buttons = MidnightUI:NewModule("Buttons", "AceEvent-3.0")
local Masque = LibStub("Masque", true)

local Container
local MasqueGroup 

local defaults = {
    profile = {
        locked = false,
        hideBG = false,
        scale = 1.0,
        fontSize = 16,
        btnWidth = 30,
        pos = {"CENTER", 0, 0},
        trayColor = {0, 0, 0, 0.7},
        btnColor = {0.1, 0.1, 0.1, 0.9},
        textColor = {1, 1, 1, 1},
        isClassic = false
    }
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function Buttons:OnInitialize()
    if not MidnightUI.db.profile.modules.buttons then return end
    self.db = MidnightUI.db:RegisterNamespace("Buttons", defaults)
    
    if Masque then
        MasqueGroup = Masque:Group("Midnight UI Buttons")
    end
    
    self:RegisterEvent("PLAYER_LOGIN")
end

function Buttons:PLAYER_LOGIN()
    self:CreateUI()
    self:UpdateAppearance()
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================

function Buttons:CreateUI()
    Container = CreateFrame("Frame", "MidnightUI_Buttons", UIParent)
    Container:SetFrameStrata("MEDIUM")
    Container:SetMovable(true)
    Container:EnableMouse(true)
    Container:SetClampedToScreen(true)
    
    Container.bg = Container:CreateTexture(nil, "BACKGROUND")
    Container.bg:SetAllPoints()
    
    Container:RegisterForDrag("LeftButton")
    
    Container:SetScript("OnDragStart", function(self) 
        if not Buttons.db.profile.locked and not InCombatLockdown() then 
            self:StartMoving() 
        end 
    end)
    
    Container:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing()
        local p, _, _, x, y = self:GetPoint()
        Buttons.db.profile.pos = {p, x, y} 
    end)
    
    Container:SetScript("OnMouseUp", function(self, button) 
        if button == "RightButton" then 
            MidnightUI:OpenConfig() 
        end 
    end)
    
    local function SetupButton(btn, textStr)
        btn:SetFrameLevel(Container:GetFrameLevel() + 5)
        btn:EnableMouse(true)
        
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        
        local h = btn:CreateTexture(nil, "HIGHLIGHT")
        h:SetAllPoints()
        btn:SetHighlightTexture(h)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(textStr)
        
        if MasqueGroup then 
            MasqueGroup:AddButton(btn) 
        end
    end
    
    local labels, macros = {"R", "E", "L"}, {"/reload", "/quit", "/logout"}
    for i = 1, 3 do
        local b = CreateFrame("Button", "MUI_Btn_"..i, Container, "SecureActionButtonTemplate")
        b:SetAttribute("type1", "macro")
        b:SetAttribute("macrotext1", macros[i])
        b:RegisterForClicks("AnyUp", "AnyDown")
        
        b:SetScript("OnMouseUp", function(self, button) 
            if button == "RightButton" then 
                MidnightUI:OpenConfig() 
            end 
        end)
        
        SetupButton(b, labels[i])
    end
    
    local btnA = CreateFrame("Button", "MUI_Btn_A", Container)
    btnA:RegisterForClicks("AnyUp")
    SetupButton(btnA, "A")
    
    btnA:SetScript("OnClick", function(self, button) 
        if button == "LeftButton" then 
            if AddonList:IsVisible() then 
                AddonList:Hide() 
            else 
                AddonList:Show() 
            end 
        elseif button == "RightButton" then 
            MidnightUI:OpenConfig() 
        end 
    end)
end

function Buttons:UpdateAppearance()
    if not Container then return end
    
    local cfg = self.db.profile
    Container:SetScale(cfg.scale)
    Container:ClearAllPoints()
    Container:SetPoint(unpack(cfg.pos))
    
    local width = cfg.btnWidth
    local totalWidth = (width * 4) + 16
    Container:SetSize(totalWidth, 36)

    if MasqueGroup or cfg.hideBG then 
        Container.bg:SetAlpha(0)
    else 
        Container.bg:SetAlpha(1)
        Container.bg:SetColorTexture(unpack(cfg.trayColor)) 
    end
    
    local function StyleBtn(btn, idx)
        btn:SetSize(width, 30)
        btn:SetPoint("LEFT", 3 + ((idx-1) * (width + 3)), 0)
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", cfg.fontSize, "OUTLINE")
        btn.text:SetTextColor(unpack(cfg.textColor))
        
        if not MasqueGroup then
            btn.bg:SetTexture(nil)
            btn.bg:SetColorTexture(unpack(cfg.btnColor))
            btn:GetHighlightTexture():SetTexture(nil)
            btn:GetHighlightTexture():SetColorTexture(1, 1, 1, 0.2)
        else
            if btn.bg then btn.bg:SetTexture(nil) end
        end
    end
    
    StyleBtn(_G["MUI_Btn_1"], 1)
    StyleBtn(_G["MUI_Btn_2"], 2)
    StyleBtn(_G["MUI_Btn_3"], 3)
    StyleBtn(_G["MUI_Btn_A"], 4)
end

-- ============================================================================
-- OPTIONS (FULL RESTORATION)
-- ============================================================================

function Buttons:GetOptions()
    return {
        type = "group", 
        name = "Buttons Tray",
        get = function(info) return self.db.profile[info[#info]] end,
        set = function(info, value) self.db.profile[info[#info]] = value; self:UpdateAppearance() end,
        args = {
            headerVisual = { type = "header", name = "Visual Settings", order = 1 },
            locked = { name = "Lock Position", type = "toggle", order = 2 },
            hideBG = { name = "Hide Background", type = "toggle", order = 3 },
            
            headerDimensions = { type = "header", name = "Dimensions", order = 10 },
            scale = { name = "Scale", type = "range", min = 0.5, max = 2, step = 0.1, order = 11 },
            btnWidth = { name = "Button Width", type = "range", min = 20, max = 50, step = 1, order = 12 },
            fontSize = { name = "Font Size", type = "range", min = 10, max = 30, step = 1, order = 13 },
            
            headerColors = { type = "header", name = "Colors", order = 20 },
            trayColor = { name = "Tray Color", type = "color", hasAlpha = true, order = 21,
                get = function() return unpack(self.db.profile.trayColor) end,
                set = function(_, r, g, b, a) self.db.profile.trayColor = {r,g,b,a}; self:UpdateAppearance() end },
            btnColor = { name = "Button Color", type = "color", hasAlpha = true, order = 22,
                get = function() return unpack(self.db.profile.btnColor) end,
                set = function(_, r, g, b, a) self.db.profile.btnColor = {r,g,b,a}; self:UpdateAppearance() end },
            textColor = { name = "Text Color", type = "color", hasAlpha = true, order = 23,
                get = function() return unpack(self.db.profile.textColor) end,
                set = function(_, r, g, b, a) self.db.profile.textColor = {r,g,b,a}; self:UpdateAppearance() end },
        }
    }
end