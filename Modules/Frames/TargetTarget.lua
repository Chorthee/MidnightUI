-- MidnightUI UnitFrames: Target of Target Frame Module


local UnitFrames = UnitFrames or _G.UnitFrames
function UnitFrames:GetTargetTargetOptions_Real()
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
