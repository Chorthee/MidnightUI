-- MidnightUI UnitFrames: Target of Target Frame Module


UnitFrames = UnitFrames or _G.UnitFrames

function UnitFrames:GetTargetTargetOptions_Real()
    local db = self.db and self.db.profile and self.db.profile.targettarget or {}
    local function update()
        if _G.MidnightUI_TargetTargetFrame then _G.MidnightUI_TargetTargetFrame:Hide(); _G.MidnightUI_TargetTargetFrame:SetParent(nil) end
        if self and self.CreateTargetTargetFrame then self:CreateTargetTargetFrame() end
    end
    return {
        type = "group",
        name = "Target of Target Frame",
        args = {
            header = { type = "header", name = "Target of Target Frame Bars", order = 0 },
            spacing = {
                type = "range",
                name = "Bar Spacing",
                desc = "Vertical space between bars.",
                min = 0, max = 32, step = 1,
                order = 0.9,
                get = function() return self.db and self.db.profile and self.db.profile.spacing or 2 end,
                set = function(_, v) if self.db and self.db.profile then self.db.profile.spacing = v; update() end end,
            },
            health = {
                type = "group",
                name = "Health Bar",
                order = 1,
                inline = true,
                args = self.GetPlayerOptions_Real and self:GetPlayerOptions_Real().args.health.args or {},
            },
            power = {
                type = "group",
                name = "Power Bar",
                order = 2,
                inline = true,
                args = self.GetPlayerOptions_Real and self:GetPlayerOptions_Real().args.power.args or {},
            },
            info = {
                type = "group",
                name = "Info Bar",
                order = 3,
                inline = true,
                args = self.GetPlayerOptions_Real and self:GetPlayerOptions_Real().args.info.args or {},
            },
        },
    }
end

-- Add any targettarget-specific logic here
