local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local Tweaks = MidnightUI:NewModule("Tweaks", "AceEvent-3.0")

local defaults = {
    profile = {
        fastLoot = true,
        hideGryphons = true,
    }
}

function Tweaks:OnInitialize()
    if not MidnightUI.db.profile.modules.tweaks then return end
    self.db = MidnightUI.db:RegisterNamespace("Tweaks", defaults)
    self:RegisterEvent("PLAYER_LOGIN")
end

function Tweaks:PLAYER_LOGIN()
    if self.db.profile.fastLoot then
        -- Set Auto Loot CVars
        SetCVar("autoLootDefault", "1")
    end
end

function Tweaks:GetOptions()
    return {
        type = "group", 
        name = "Tweaks",
        get = function(info) return self.db.profile[info[#info]] end,
        set = function(info, value) self.db.profile[info[#info]] = value end,
        args = {
            fastLoot = { name = "Fast Loot", type = "toggle", order = 1 },
            hideGryphons = { name = "Hide Action Bar Art", type = "toggle", order = 2,
                set = function(_, v) self.db.profile.hideGryphons = v; C_UI.Reload() end },
        }
    }
end