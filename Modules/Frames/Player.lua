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
