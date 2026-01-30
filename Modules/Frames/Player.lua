-- MidnightUI UnitFrames: Player Frame Module


UnitFrames = UnitFrames or _G.UnitFrames



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
            -- ...existing code for other bars and options...
        },
    }
                name = "Info Bar",
                order = 3,
                inline = true,
                args = {
                    -- Show Available Tags button removed
                    enabled = { type = "toggle", name = "Show", order = 1, get = function() return db.info and db.info.enabled end, set = function(_, v) db.info.enabled = v; update() end },
                    attachTo = {
                        type = "select",
                        name = "Attach To",
                        desc = "Attach the Info Bar to another bar. If hidden, attached bars will follow the selected bar.",
                        order = 1.5,
                        values = { health = "Health Bar", power = "Power Bar", info = "Info Bar", none = "None" },
                        get = function() return db.info and db.info.attachTo or "health" end,
                        set = function(_, v) db.info.attachTo = v; update() end,
                    },
                    width = { type = "range", name = "Width", min = 50, max = 600, step = 1, order = 2, get = function() return db.info and db.info.width or 220 end, set = function(_, v) db.info.width = v; update() end },
                    height = { type = "range", name = "Height", min = 5, max = 100, step = 1, order = 3, get = function() return db.info and db.info.height or 10 end, set = function(_, v) db.info.height = v; update() end },
                    classColor = { type = "toggle", name = "Class Colored Bar", desc = "Use your class color for the info bar.", order = 3.9, get = function() return db.info and db.info.classColor end, set = function(_, v) db.info.classColor = v; update() end },
                    color = { type = "color", name = "Bar Color", hasAlpha = true, order = 4, get = function() return unpack(db.info and db.info.color or {0.8,0.8,0.2,1}) end, set = function(_, r,g,b,a) db.info.color = {r,g,b,a}; update() end },
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
                    fontClassColor = { type = "toggle", name = "Class Colored Font", desc = "Use your class color for the info bar text.", order = 9.5, get = function() return db.info and db.info.fontClassColor end, set = function(_, v) db.info.fontClassColor = v; update() end },
                    bgColor = { type = "color", name = "Background Color", hasAlpha = true, order = 5, get = function() return unpack(db.info and db.info.bgColor or {0,0,0,0.5}) end, set = function(_, r,g,b,a) db.info.bgColor = {r,g,b,a}; update() end },
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
                    fontSize = { type = "range", name = "Font Size", min = 6, max = 32, step = 1, order = 7, get = function() return db.info and db.info.fontSize or 10 end, set = function(_, v) db.info.fontSize = v; update() end },
                    fontOutline = { type = "select", name = "Font Outline", order = 8, values = { NONE = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" }, get = function() return db.info and db.info.fontOutline or "OUTLINE" end, set = function(_, v) db.info.fontOutline = v; update() end },
                    fontColor = { type = "color", name = "Font Color", hasAlpha = true, order = 9, get = function() return unpack(db.info and db.info.fontColor or {1,1,1,1}) end, set = function(_, r,g,b,a) db.info.fontColor = {r,g,b,a}; update() end }
                    -- Text Preset and custom text fields removed (static text only)
                    ,textPos = { type = "select", name = "Text Position", order = 11, values = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" }, get = function() return db.info and db.info.textPos or "CENTER" end, set = function(_, v) db.info.textPos = v; update() end }
                    ,texture = {
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
                        get = function() return db.info and db.info.texture or "Flat" end,
                        set = function(_, v) db.info.texture = v; update() end
                    }
                },
            },
        },
    }
end

-- Add any player-specific logic here
