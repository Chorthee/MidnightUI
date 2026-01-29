-- MidnightUI UnitFrames: Target of Target Frame Module
local _, ns = ...
local MidnightUI = LibStub("AceAddon-3.0"):GetAddon("MidnightUI")
local UnitFrames = MidnightUI:GetModule("UnitFrames")

function UnitFrames:GetTargetTargetOptions()
    -- Target of Target frame options table
    local options = {
        type = "group",
        name = "Target of Target Frame",
        args = {
            -- ...targettarget-specific options here...
        },
    }
    return options
end

-- Add any targettarget-specific logic here
