-- MidnightUI UnitFrames: Player Frame Module


if _G.UnitFrames then UnitFrames = _G.UnitFrames end



function UnitFrames:GetPlayerOptions_Real()
    local db = self.db and self.db.profile and self.db.profile.player or {}
    local function update()
        if _G.MidnightUI_PlayerFrame then _G.MidnightUI_PlayerFrame:Hide(); _G.MidnightUI_PlayerFrame:SetParent(nil) end
        if self and self.CreatePlayerFrame then self:CreatePlayerFrame() end
    end
    return {
        type = "group",
        name = "Player Frame",
        args = {
            header = { type = "header", name = "Player Frame Bars", order = 0 },
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
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Show",
                        order = 1,
                        get = function() return db.health and db.health.enabled end,
                        set = function(_, v) db.health.enabled = v; update() end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        min = 50, max = 600, step = 1,
                        order = 2,
                        get = function() return db.health and db.health.width or 220 end,
                        set = function(_, v) db.health.width = v; update() end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        min = 5, max = 100, step = 1,
                        order = 3,
                        get = function() return db.health and db.health.height or 24 end,
                        set = function(_, v) db.health.height = v; update() end,
                    },
                    classColor = {
                        type = "toggle",
                        name = "Class Colored Bar",
                        desc = "Use your class color for the health bar.",
                        order = 3.9,
                        get = function() return db.health and db.health.classColor end,
                        set = function(_, v) db.health.classColor = v; update() end,
                    },
                    color = {
                        type = "color",
                        name = "Bar Color",
                        hasAlpha = true,
                        order = 4,
                        get = function() return unpack(db.health and db.health.color or {0.2,0.8,0.2,1}) end,
                        set = function(_, r,g,b,a) db.health.color = {r,g,b,a}; update() end,
                    },
                    alpha = {
                        type = "range",
                        name = "Bar Transparency",
                        desc = "Set the transparency of the health bar.",
                        min = 0, max = 100, step = 1, order = 4.1,
                        get = function() return math.floor(100 * (db.health and db.health.alpha or (db.health and db.health.color and db.health.color[4]) or 1) + 0.5) end,
                        set = function(_, v)
                            local alpha = v / 100
                            db.health.alpha = alpha
                            if db.health and db.health.color then
                                db.health.color[4] = alpha
                            else
                                db.health.color = {0.2, 0.8, 0.2, alpha}
                            end
                            update()
                        end,
                        bigStep = 5,
                    },
                    fontClassColor = {
                        type = "toggle",
                        name = "Class Colored Font",
                        desc = "Use your class color for the health bar text.",
                        order = 9.5,
                        get = function() return db.health and db.health.fontClassColor end,
                        set = function(_, v) db.health.fontClassColor = v; update() end,
                    },
                    bgColor = {
                        type = "color",
                        name = "Background Color",
                        hasAlpha = true,
                        order = 5,
                        get = function() return unpack(db.health and db.health.bgColor or {0,0,0,0.5}) end,
                        set = function(_, r,g,b,a) db.health.bgColor = {r,g,b,a}; update() end,
                    },
                    font = {
                        type = "select",
                        name = "Font",
                        order = 6,
                        values = function()
                            local fonts = self.LSM and self.LSM:List("font") or (LibStub and LibStub("LibSharedMedia-3.0"):List("font")) or {}
                            local out = {}
                            for _, font in ipairs(fonts) do out[font] = font end
                            return out
                        end,
                        get = function() return db.health and db.health.font or "Friz Quadrata TT" end,
                        set = function(_, v) db.health.font = v; update() end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Font Size",
                        min = 6, max = 32, step = 1,
                        order = 7,
                        get = function() return db.health and db.health.fontSize or 14 end,
                        set = function(_, v) db.health.fontSize = v; update() end,
                    },
                    fontOutline = {
                        type = "select",
                        name = "Font Outline",
                        order = 8,
                        values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" },
                        get = function() return db.health and db.health.fontOutline or "OUTLINE" end,
                        set = function(_, v) db.health.fontOutline = v; update() end,
                    },
                    fontColor = {
                        type = "color",
                        name = "Font Color",
                        hasAlpha = true,
                        order = 9,
                        get = function() return unpack(db.health and db.health.fontColor or {1,1,1,1}) end,
                        set = function(_, r,g,b,a) db.health.fontColor = {r,g,b,a}; update() end,
                    },
                    textPos = {
                        type = "select",
                        name = "Text Position",
                        order = 11,
                        values = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" },
                        get = function() return db.health and db.health.textPos or "CENTER" end,
                        set = function(_, v) db.health.textPos = v; update() end,
                    },
                    texture = {
                        type = "select",
                        name = "Texture",
                        order = 12,
                        values = function()
                            local LSM = self.LSM or (LibStub and LibStub("LibSharedMedia-3.0"))
                            local textures = LSM and LSM:List("statusbar") or {}
                            local out = {}
                            for _, tex in ipairs(textures) do out[tex] = tex end
                            return out
                        end,
                        get = function() return db.health and db.health.texture or "Flat" end,
                        set = function(_, v) db.health.texture = v; update() end,
                    },
                },
            },

            power = {
                type = "group",
                name = "Power Bar",
                order = 2,
                inline = true,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Show",
                        order = 1,
                        get = function() return db.power and db.power.enabled end,
                        set = function(_, v) db.power.enabled = v; update() end,
                    },
                    attachTo = {
                        type = "select",
                        name = "Attach To",
                        desc = "Attach the Power Bar to another bar.",
                        order = 1.5,
                        values = { health = "Health Bar", power = "Power Bar", info = "Info Bar", none = "None" },
                        get = function() return db.power and db.power.attachTo or "health" end,
                        set = function(_, v) db.power.attachTo = v; update() end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        min = 50, max = 600, step = 1,
                        order = 2,
                        get = function() return db.power and db.power.width or 220 end,
                        set = function(_, v) db.power.width = v; update() end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        min = 5, max = 100, step = 1,
                        order = 3,
                        get = function() return db.power and db.power.height or 12 end,
                        set = function(_, v) db.power.height = v; update() end,
                    },
                    classColor = {
                        type = "toggle",
                        name = "Class Colored Bar",
                        desc = "Use your class color for the power bar.",
                        order = 3.9,
                        get = function() return db.power and db.power.classColor end,
                        set = function(_, v)
                            db.power.classColor = v
                            if _G.MidnightUI_PlayerFrame then _G.MidnightUI_PlayerFrame:Hide(); _G.MidnightUI_PlayerFrame:SetParent(nil) end
                            if self and self.CreatePlayerFrame then self:CreatePlayerFrame() end
                        end,
                    },
                    color = {
                        type = "color",
                        name = "Bar Color",
                        hasAlpha = true,
                        order = 4,
                        get = function() return unpack(db.power and db.power.color or {0.2,0.4,0.8,1}) end,
                        set = function(_, r,g,b,a) db.power.color = {r,g,b,a}; update() end,
                    },
                    alpha = {
                        type = "range",
                        name = "Bar Transparency",
                        desc = "Set the transparency of the power bar.",
                        min = 0, max = 100, step = 1, order = 4.1,
                        get = function() return math.floor(100 * (db.power and db.power.alpha or (db.power and db.power.color and db.power.color[4]) or 1) + 0.5) end,
                        set = function(_, v)
                            local alpha = v / 100
                            db.power.alpha = alpha
                            if db.power and db.power.color then
                                db.power.color[4] = alpha
                            else
                                db.power.color = {0.2, 0.4, 0.8, alpha}
                            end
                            update()
                        end,
                        bigStep = 5,
                    },
                    fontClassColor = {
                        type = "toggle",
                        name = "Class Colored Font",
                        desc = "Use your class color for the power bar text.",
                        order = 9.5,
                        get = function() return db.power and db.power.fontClassColor end,
                        set = function(_, v) db.power.fontClassColor = v; update() end,
                    },
                    bgColor = {
                        type = "color",
                        name = "Background Color",
                        hasAlpha = true,
                        order = 5,
                        get = function() return unpack(db.power and db.power.bgColor or {0,0,0,0.5}) end,
                        set = function(_, r,g,b,a) db.power.bgColor = {r,g,b,a}; update() end,
                    },
                    font = {
                        type = "select",
                        name = "Font",
                        order = 6,
                        values = function()
                            local fonts = self.LSM and self.LSM:List("font") or (LibStub and LibStub("LibSharedMedia-3.0"):List("font")) or {}
                            local out = {}
                            for _, font in ipairs(fonts) do out[font] = font end
                            return out
                        end,
                        get = function() return db.power and db.power.font or "Friz Quadrata TT" end,
                        set = function(_, v) db.power.font = v; update() end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Font Size",
                        min = 6, max = 32, step = 1,
                        order = 7,
                        get = function() return db.power and db.power.fontSize or 12 end,
                        set = function(_, v) db.power.fontSize = v; update() end,
                    },
                    fontOutline = {
                        type = "select",
                        name = "Font Outline",
                        order = 8,
                        values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" },
                        get = function() return db.power and db.power.fontOutline or "OUTLINE" end,
                        set = function(_, v) db.power.fontOutline = v; update() end,
                    },
                    fontColor = {
                        type = "color",
                        name = "Font Color",
                        hasAlpha = true,
                        order = 9,
                        get = function() return unpack(db.power and db.power.fontColor or {1,1,1,1}) end,
                        set = function(_, r,g,b,a) db.power.fontColor = {r,g,b,a}; update() end,
                    },
                },
            },

            info = {
                type = "group",
                name = "Info Bar",
                order = 3,
                inline = true,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Show",
                        order = 1,
                        get = function() return db.info and db.info.enabled end,
                        set = function(_, v) db.info.enabled = v; update() end,
                    },
                    attachTo = {
                        type = "select",
                        name = "Attach To",
                        desc = "Attach the Info Bar to another bar.",
                        order = 1.5,
                        values = { health = "Health Bar", power = "Power Bar", info = "Info Bar", none = "None" },
                        get = function() return db.info and db.info.attachTo or "health" end,
                        set = function(_, v) db.info.attachTo = v; update() end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        min = 50, max = 600, step = 1,
                        order = 2,
                        get = function() return db.info and db.info.width or 220 end,
                        set = function(_, v) db.info.width = v; update() end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        min = 5, max = 100, step = 1,
                        order = 3,
                        get = function() return db.info and db.info.height or 10 end,
                        set = function(_, v) db.info.height = v; update() end,
                    },
                    classColor = {
                        type = "toggle",
                        name = "Class Colored Bar",
                        desc = "Use your class color for the info bar.",
                        order = 3.9,
                        get = function() return db.info and db.info.classColor end,
                        set = function(_, v) db.info.classColor = v; update() end,
                    },
                    color = {
                        type = "color",
                        name = "Bar Color",
                        hasAlpha = true,
                        order = 4,
                        get = function() return unpack(db.info and db.info.color or {0.8,0.8,0.2,1}) end,
                        set = function(_, r,g,b,a) db.info.color = {r,g,b,a}; update() end,
                    },
                    alpha = {
                        type = "range",
                        name = "Bar Transparency",
                        desc = "Set the transparency of the info bar.",
                        min = 0, max = 100, step = 1, order = 4.1,
                        get = function() return math.floor(100 * (db.info and db.info.alpha or (db.info and db.info.color and db.info.color[4]) or 1) + 0.5) end,
                        set = function(_, v)
                            local alpha = v / 100
                            db.info.alpha = alpha
                            if db.info and db.info.color then
                                db.info.color[4] = alpha
                            else
                                db.info.color = {0.8, 0.8, 0.2, alpha}
                            end
                            update()
                        end,
                        bigStep = 5,
                    },
                    fontClassColor = {
                        type = "toggle",
                        name = "Class Colored Font",
                        desc = "Use your class color for the info bar text.",
                        order = 9.5,
                        get = function() return db.info and db.info.fontClassColor end,
                        set = function(_, v) db.info.fontClassColor = v; update() end,
                    },
                    bgColor = {
                        type = "color",
                        name = "Background Color",
                        hasAlpha = true,
                        order = 5,
                        get = function() return unpack(db.info and db.info.bgColor or {0,0,0,0.5}) end,
                        set = function(_, r,g,b,a) db.info.bgColor = {r,g,b,a}; update() end,
                    },
                    font = {
                        type = "select",
                        name = "Font",
                        order = 6,
                        values = function()
                            local fonts = self.LSM and self.LSM:List("font") or (LibStub and LibStub("LibSharedMedia-3.0"):List("font")) or {}
                            local out = {}
                            for _, font in ipairs(fonts) do out[font] = font end
                            return out
                        end,
                        get = function() return db.info and db.info.font or "Friz Quadrata TT" end,
                        set = function(_, v) db.info.font = v; update() end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Font Size",
                        min = 6, max = 32, step = 1,
                        order = 7,
                        get = function() return db.info and db.info.fontSize or 10 end,
                        set = function(_, v) db.info.fontSize = v; update() end,
                    },
                    fontOutline = {
                        type = "select",
                        name = "Font Outline",
                        order = 8,
                        values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" },
                        get = function() return db.info and db.info.fontOutline or "OUTLINE" end,
                        set = function(_, v) db.info.fontOutline = v; update() end,
                    },
                    fontColor = {
                        type = "color",
                        name = "Font Color",
                        hasAlpha = true,
                        order = 9,
                        get = function() return unpack(db.info and db.info.fontColor or {1,1,1,1}) end,
                        set = function(_, r,g,b,a) db.info.fontColor = {r,g,b,a}; update() end,
                    },
                },
            },
        },
    }
end


