local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local CD = MidnightUI:NewModule("Cooldowns")

function CD:OnInitialize()
    if not MidnightUI.db.profile.modules.cooldowns then return end
    
    -- Hook the CooldownFrame_Set function to capture all cooldowns
    hooksecurefunc("CooldownFrame_Set", function(self, start, duration, enable, forceShowDrawEdge, modRate)
        if enable and enable > 0 and start > 0 and duration > 2.0 then
            CD:CreateTimer(self)
        else
            if self.muiText then self.muiText:Hide() end
        end
    end)
end

function CD:CreateTimer(cdFrame)
    if not cdFrame.muiText then
        cdFrame.muiText = cdFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        cdFrame.muiText:SetPoint("CENTER", 0, 0)
        cdFrame.muiText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    end
    
    cdFrame.muiText:Show()
    cdFrame:SetScript("OnUpdate", function(self, elapsed)
        if not self.nextUp or self.nextUp < 0 then
            self.nextUp = 0.1
            local start, duration = self:GetCooldownTimes()
            if not start then return end
            
            local now = GetTime()
            local remain = (start + duration) - now
            
            if remain <= 0 then
                self.muiText:Hide()
            elseif remain < 60 then
                self.muiText:SetText(math.floor(remain))
                self.muiText:SetTextColor(1, 1, 0) -- Yellow for seconds
            else
                self.muiText:SetText(math.ceil(remain / 60) .. "m")
                self.muiText:SetTextColor(1, 1, 1) -- White for minutes
            end
        else
            self.nextUp = self.nextUp - elapsed
        end
    end)
end