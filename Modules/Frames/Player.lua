-- MidnightUI UnitFrames: Player Frame Module


UnitFrames = UnitFrames or _G.UnitFrames


function UnitFrames:GetPlayerOptions_Real()
    local db = self.db and self.db.profile and self.db.profile.player or {}
    return {
        type = "group",
        name = "Player Frame",
        args = {
            header = { type = "header", name = "Player Frame Bars", order = 0 },
            -- Health Bar
            health = {
                type = "group",
                name = "Health Bar",
                order = 1,
                inline = true,
                args = {
                    enabled = { type = "toggle", name = "Show", order = 1, get = function() return db.health and db.health.enabled end, set = function(_, v) db.health.enabled = v end },
                    width = { type = "range", name = "Width", min = 50, max = 600, step = 1, order = 2, get = function() return db.health and db.health.width or 220 end, set = function(_, v) db.health.width = v end },
                    height = { type = "range", name = "Height", min = 5, max = 100, step = 1, order = 3, get = function() return db.health and db.health.height or 24 end, set = function(_, v) db.health.height = v end },
                    color = { type = "color", name = "Bar Color", hasAlpha = true, order = 4, get = function() return unpack(db.health and db.health.color or {0.2,0.8,0.2,1}) end, set = function(_, r,g,b,a) db.health.color = {r,g,b,a} end },
                    bgColor = { type = "color", name = "Background Color", hasAlpha = true, order = 5, get = function() return unpack(db.health and db.health.bgColor or {0,0,0,0.5}) end, set = function(_, r,g,b,a) db.health.bgColor = {r,g,b,a} end },
                    font = { type = "input", name = "Font", order = 6, get = function() return db.health and db.health.font or "Friz Quadrata TT" end, set = function(_, v) db.health.font = v end },
                    fontSize = { type = "range", name = "Font Size", min = 6, max = 32, step = 1, order = 7, get = function() return db.health and db.health.fontSize or 14 end, set = function(_, v) db.health.fontSize = v end },
                    fontOutline = { type = "select", name = "Font Outline", order = 8, values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" }, get = function() return db.health and db.health.fontOutline or "OUTLINE" end, set = function(_, v) db.health.fontOutline = v end },
                    fontColor = { type = "color", name = "Font Color", hasAlpha = true, order = 9, get = function() return unpack(db.health and db.health.fontColor or {1,1,1,1}) end, set = function(_, r,g,b,a) db.health.fontColor = {r,g,b,a} end },
                    text = { type = "input", name = "Text Format", order = 10, get = function() return db.health and db.health.text or "[curhp] / [maxhp] ([perhp]%)" end, set = function(_, v) db.health.text = v end },
                    textPos = { type = "select", name = "Text Position", order = 11, values = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" }, get = function() return db.health and db.health.textPos or "CENTER" end, set = function(_, v) db.health.textPos = v end },
                    texture = { type = "input", name = "Texture", order = 12, get = function() return db.health and db.health.texture or "Flat" end, set = function(_, v) db.health.texture = v end },
                },
            },
            -- Power Bar
            power = {
                type = "group",
                name = "Power Bar",
                order = 2,
                inline = true,
                args = {
                    enabled = { type = "toggle", name = "Show", order = 1, get = function() return db.power and db.power.enabled end, set = function(_, v) db.power.enabled = v end },
                    width = { type = "range", name = "Width", min = 50, max = 600, step = 1, order = 2, get = function() return db.power and db.power.width or 220 end, set = function(_, v) db.power.width = v end },
                    height = { type = "range", name = "Height", min = 5, max = 100, step = 1, order = 3, get = function() return db.power and db.power.height or 12 end, set = function(_, v) db.power.height = v end },
                    color = { type = "color", name = "Bar Color", hasAlpha = true, order = 4, get = function() return unpack(db.power and db.power.color or {0.2,0.4,0.8,1}) end, set = function(_, r,g,b,a) db.power.color = {r,g,b,a} end },
                    bgColor = { type = "color", name = "Background Color", hasAlpha = true, order = 5, get = function() return unpack(db.power and db.power.bgColor or {0,0,0,0.5}) end, set = function(_, r,g,b,a) db.power.bgColor = {r,g,b,a} end },
                    font = { type = "input", name = "Font", order = 6, get = function() return db.power and db.power.font or "Friz Quadrata TT" end, set = function(_, v) db.power.font = v end },
                    fontSize = { type = "range", name = "Font Size", min = 6, max = 32, step = 1, order = 7, get = function() return db.power and db.power.fontSize or 12 end, set = function(_, v) db.power.fontSize = v end },
                    fontOutline = { type = "select", name = "Font Outline", order = 8, values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" }, get = function() return db.power and db.power.fontOutline or "OUTLINE" end, set = function(_, v) db.power.fontOutline = v end },
                    fontColor = { type = "color", name = "Font Color", hasAlpha = true, order = 9, get = function() return unpack(db.power and db.power.fontColor or {1,1,1,1}) end, set = function(_, r,g,b,a) db.power.fontColor = {r,g,b,a} end },
                    text = { type = "input", name = "Text Format", order = 10, get = function() return db.power and db.power.text or "[curpp] / [maxpp]" end, set = function(_, v) db.power.text = v end },
                    textPos = { type = "select", name = "Text Position", order = 11, values = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" }, get = function() return db.power and db.power.textPos or "CENTER" end, set = function(_, v) db.power.textPos = v end },
                    texture = { type = "input", name = "Texture", order = 12, get = function() return db.power and db.power.texture or "Flat" end, set = function(_, v) db.power.texture = v end },
                },
            },
            -- Info Bar
            info = {
                type = "group",
                name = "Info Bar",
                order = 3,
                inline = true,
                args = {
                    enabled = { type = "toggle", name = "Show", order = 1, get = function() return db.info and db.info.enabled end, set = function(_, v) db.info.enabled = v end },
                    width = { type = "range", name = "Width", min = 50, max = 600, step = 1, order = 2, get = function() return db.info and db.info.width or 220 end, set = function(_, v) db.info.width = v end },
                    height = { type = "range", name = "Height", min = 5, max = 100, step = 1, order = 3, get = function() return db.info and db.info.height or 10 end, set = function(_, v) db.info.height = v end },
                    color = { type = "color", name = "Bar Color", hasAlpha = true, order = 4, get = function() return unpack(db.info and db.info.color or {0.8,0.8,0.2,1}) end, set = function(_, r,g,b,a) db.info.color = {r,g,b,a} end },
                    bgColor = { type = "color", name = "Background Color", hasAlpha = true, order = 5, get = function() return unpack(db.info and db.info.bgColor or {0,0,0,0.5}) end, set = function(_, r,g,b,a) db.info.bgColor = {r,g,b,a} end },
                    font = { type = "input", name = "Font", order = 6, get = function() return db.info and db.info.font or "Friz Quadrata TT" end, set = function(_, v) db.info.font = v end },
                    fontSize = { type = "range", name = "Font Size", min = 6, max = 32, step = 1, order = 7, get = function() return db.info and db.info.fontSize or 10 end, set = function(_, v) db.info.fontSize = v end },
                    fontOutline = { type = "select", name = "Font Outline", order = 8, values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" }, get = function() return db.info and db.info.fontOutline or "OUTLINE" end, set = function(_, v) db.info.fontOutline = v end },
                    fontColor = { type = "color", name = "Font Color", hasAlpha = true, order = 9, get = function() return unpack(db.info and db.info.fontColor or {1,1,1,1}) end, set = function(_, r,g,b,a) db.info.fontColor = {r,g,b,a} end },
                    text = { type = "input", name = "Text Format", order = 10, get = function() return db.info and db.info.text or "[name] [level] [class]" end, set = function(_, v) db.info.text = v end },
                    textPos = { type = "select", name = "Text Position", order = 11, values = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" }, get = function() return db.info and db.info.textPos or "CENTER" end, set = function(_, v) db.info.textPos = v end },
                    texture = { type = "input", name = "Texture", order = 12, get = function() return db.info and db.info.texture or "Flat" end, set = function(_, v) db.info.texture = v end },
                },
            },
        },
    }
end

-- Add any player-specific logic here
