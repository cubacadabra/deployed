-- GENERATED FILE: do not edit; edit src/ and run cubacadabra build-game.
-- game: second-game
-- version: 1

-- Portable entry point for the second-game package.
--
-- The build step expands these includes into one sandboxed Luau chunk for the
-- shared Rust runtime. Keeping the includes explicit makes load order visible
-- without requiring a runtime filesystem or module loader.

-- begin include: ui/styles.luau
local GameUIStyles = {}

GameUIStyles.colors = {
    ink = "#0B102BF5",
    inkRaised = "#1A2152F7",
    keyline = "#B7F7E4A8",
    paper = "#F7F5E9FF",
    blue = "#57E5D0FF",
    coral = "#FF8A3DFF",
}

function GameUIStyles.control_style(background, accent, foreground, radius)
    return {
        background = background,
        borderColor = "#070B20B8",
        borderWidth = 3,
        cornerRadius = radius or 17,
        foreground = foreground or GameUIStyles.colors.paper,
        accent = accent or GameUIStyles.colors.blue,
        textAlign = "center",
        fontSize = 14,
    }
end

function GameUIStyles.popover_style()
    return {
        background = GameUIStyles.colors.inkRaised,
        borderColor = GameUIStyles.colors.keyline,
        borderWidth = 2,
        cornerRadius = 20,
        foreground = GameUIStyles.colors.paper,
    }
end
-- end include: ui/styles.luau
-- begin include: ui/document.luau
local GameUIDocument = {}

local function shape_trigger(id, icon, visible)
    return {
        id = id,
        kind = "button",
        icon = icon,
        action = "build.shape.toggle",
        visible = visible,
        visibleIn = { "real-game" },
        layout = { region = "header", width = 56, height = 56 },
        style = GameUIStyles.control_style("#1A2152F7", "#57E5D0FF"),
    }
end

local function color_trigger(id, label, background, foreground, visible)
    return {
        id = id,
        kind = "button",
        icon = "colorswap",
        action = "build.color.toggle",
        visible = visible,
        visibleIn = { "real-game" },
        layout = { region = "header", width = 56, height = 56 },
        style = GameUIStyles.control_style(background, "#57E5D0FF", foreground),
    }
end

local function shape_choice(id, icon, label, checked)
    return {
        id = "build-shape-" .. id,
        kind = "button",
        icon = icon,
        text = label,
        action = "build.shape." .. id,
        checked = checked,
        layout = { width = 96, height = 88 },
        style = GameUIStyles.control_style("#20295DFF", "#57E5D0FF", "#F7F5E9FF", 16),
    }
end

local function color_choice(id, background, foreground, checked)
    return {
        id = "build-color-" .. id,
        kind = "button",
        action = "build.color." .. id,
        checked = checked,
        layout = { width = 56, height = 56 },
        style = GameUIStyles.control_style(background, "#57E5D0FF", foreground, 18),
    }
end

function GameUIDocument.create()
    return {
        nodes = {
            shape_trigger("build-shape-trigger-cube", "cube", false),
            shape_trigger("build-shape-trigger-beam", "beam", true),
            shape_trigger("build-shape-trigger-slab", "slab", false),

            color_trigger("build-color-trigger-coral", "orange", "#FF8A3DFF", "#0B102BFF", false),
            color_trigger("build-color-trigger-butter", "acid", "#F1E95BFF", "#0B102BFF", false),
            color_trigger("build-color-trigger-periwinkle", "violet", "#9F7BFFFF", "#F7F5E9FF", true),
            color_trigger("build-color-trigger-ink", "midnight", "#171B43FF", "#F7F5E9FF", false),
            color_trigger("build-color-trigger-paper", "warm white", "#F7F5E9FF", "#0B102BFF", false),

            -- This transparent outside-tap target closes either selector
            -- without visually obscuring the world.
            {
                id = "build-popover-catcher",
                kind = "modal",
                action = "build.popover.close",
                blocksInput = true,
                visible = false,
                visibleIn = { "real-game" },
                layout = { width = "fill", height = "fill", ignoreSafeArea = true },
            },
            {
                id = "build-shape-popover",
                kind = "menu",
                blocksInput = true,
                visible = false,
                visibleIn = { "real-game" },
                layout = {
                    anchor = "topLeft",
                    width = 336,
                    height = 136,
                    offset = { 316, 88 },
                    padding = 12,
                    direction = "column",
                    align = "stretch",
                    gap = 8,
                },
                style = GameUIStyles.popover_style(),
                children = {
                    {
                        id = "build-shape-title",
                        kind = "text",
                        text = "CHOOSE A SHAPE",
                        layout = { width = "fill", height = 20 },
                        style = { fontSize = 15, foreground = "#F7F5E9FF" },
                    },
                    {
                        id = "build-shape-options",
                        kind = "stack",
                        layout = { width = "fill", height = 88, direction = "row", align = "center", gap = 10 },
                        children = {
                            shape_choice("cube", "cube", "CUBE", false),
                            shape_choice("beam", "beam", "BEAM", true),
                            shape_choice("slab", "slab", "SLAB", false),
                        },
                    },
                },
            },
            {
                id = "build-color-popover",
                kind = "menu",
                blocksInput = true,
                visible = false,
                visibleIn = { "real-game" },
                layout = {
                    anchor = "topLeft",
                    width = 336,
                    height = 108,
                    offset = { 380, 88 },
                    padding = 12,
                    direction = "column",
                    align = "stretch",
                    gap = 8,
                },
                style = GameUIStyles.popover_style(),
                children = {
                    {
                        id = "build-color-title",
                        kind = "text",
                        text = "CHOOSE A COLOR",
                        layout = { width = "fill", height = 20 },
                        style = { fontSize = 15, foreground = "#F7F8EEFF" },
                    },
                    {
                        id = "build-color-options",
                        kind = "stack",
                        layout = { width = "fill", height = 56, direction = "row", align = "center", gap = 7 },
                        children = {
                            color_choice("coral", "#FF8A3DFF", "#0B102BFF", false),
                            color_choice("butter", "#F1E95BFF", "#0B102BFF", false),
                            color_choice("periwinkle", "#9F7BFFFF", "#F7F5E9FF", true),
                            color_choice("ink", "#171B43FF", "#F7F5E9FF", false),
                            color_choice("paper", "#F7F5E9FF", "#0B102BFF", false),
                        },
                    },
                },
            },

            {
                id = "build-context",
                kind = "panel",
                visibleIn = { "real-game" },
                layout = {
                    region = "bottomCenter",
                    width = "auto",
                    height = 68,
                    padding = 5,
                    direction = "row",
                    align = "center",
                    gap = 8,
                },
                style = {
                    background = "#0B102BE8",
                    borderColor = "#B7F7E466",
                    borderWidth = 2,
                    cornerRadius = 18,
                },
                children = {
                    {
                        id = "second-game-label",
                        kind = "stack",
                        layout = { width = 116, height = 58, direction = "column", align = "start", gap = 2 },
                        children = {
                            {
                                id = "second-game-name",
                                kind = "text",
                                text = "SIGNAL RUN",
                                layout = { width = "fill", height = 22 },
                                style = { fontSize = 14, foreground = "#57E5D0FF" },
                            },
                            {
                                id = "second-game-status",
                                kind = "text",
                                text = "DROP BEACON 0/4",
                                layout = { width = "fill", height = 30 },
                                style = { fontSize = 11, foreground = "#F7F5E9FF" },
                            },
                        },
                    },
                    {
                        id = "build-place",
                        kind = "button",
                        icon = "place",
                        action = "build.place",
                        layout = { width = 58, height = 58 },
                        style = GameUIStyles.control_style("#57E5D0FF", "#57E5D0FF", "#0B102BFF", 18),
                    },
                    {
                        id = "build-rotate",
                        kind = "button",
                        icon = "rotate",
                        action = "build.rotate",
                        layout = { width = 58, height = 58 },
                        style = GameUIStyles.control_style("#20295DFF", "#57E5D0FF", "#F7F5E9FF", 18),
                    },
                    {
                        id = "build-remove",
                        kind = "button",
                        icon = "trash",
                        action = "build.remove",
                        layout = { width = 58, height = 58 },
                        style = GameUIStyles.control_style("#B64C6FFF", "#FF8A3DFF", "#F7F5E9FF", 18),
                    },
                },
            },
            {
                id = "player-joystick",
                kind = "joystick",
                action = "player.move",
                layout = { anchor = "bottomLeft", width = 120, height = 120, offset = { 20, -24 } },
                style = {
                    background = "#0B102BC9",
                    borderColor = "#B7F7E455",
                    borderWidth = 2,
                    cornerRadius = 60,
                    accent = "#57E5D0FF",
                },
            },
            {
                id = "player-jump",
                kind = "button",
                text = "JUMP",
                action = "player.jump",
                layout = { anchor = "bottomRight", width = 86, height = 44, offset = { -22, -84 } },
                style = GameUIStyles.control_style("#1A2152E8", "#57E5D0FF", "#F7F5E9FF", 14),
            },
            {
                id = "player-run",
                kind = "button",
                text = "RUN",
                action = "player.run",
                layout = { anchor = "bottomRight", width = 86, height = 44, offset = { -22, -30 } },
                style = GameUIStyles.control_style("#1A2152E8", "#57E5D0FF", "#F7F5E9FF", 14),
            },
        },
    }
end
-- end include: ui/document.luau
-- begin include: ui/actions.luau
local GameUIActions = {}

local shapes = {
    ["build.shape.cube"] = "cube",
    ["build.shape.beam"] = "beam",
    ["build.shape.slab"] = "slab",
}

local colors = {
    ["build.color.coral"] = "coral",
    ["build.color.butter"] = "butter",
    ["build.color.periwinkle"] = "periwinkle",
    ["build.color.ink"] = "ink",
    ["build.color.paper"] = "paper",
}

local shape_ids = { "cube", "beam", "slab" }
local color_ids = { "coral", "butter", "periwinkle", "ink", "paper" }
local beacon_count = 0

local function close_popovers(api)
    api.ui.open_popover = nil
    api.ui:set_visible("build-popover-catcher", false)
    api.ui:set_visible("build-shape-popover", false)
    api.ui:set_visible("build-color-popover", false)
end

local function open_popover(api, name)
    local should_open = api.ui.open_popover ~= name
    close_popovers(api)
    if should_open then
        api.ui.open_popover = name
        api.ui:set_visible("build-popover-catcher", true)
        api.ui:set_visible("build-" .. name .. "-popover", true)
    end
end

local function select_shape(api, shape)
    api.ui.selected_shape = shape
    for _, id in ipairs(shape_ids) do
        api.ui:set_checked("build-shape-" .. id, id == shape)
        api.ui:set_visible("build-shape-trigger-" .. id, id == shape)
    end
    close_popovers(api)
end

local function select_color(api, color)
    api.ui.selected_color = color
    for _, id in ipairs(color_ids) do
        api.ui:set_checked("build-color-" .. id, id == color)
        api.ui:set_visible("build-color-trigger-" .. id, id == color)
    end
    close_popovers(api)
end

function GameUIActions.handle(api, event)
    if event.phase ~= "activate" then
        return
    end
    if event.action == "build.shape.toggle" then
        open_popover(api, "shape")
    elseif event.action == "build.color.toggle" then
        open_popover(api, "color")
    elseif event.action == "build.popover.close" then
        close_popovers(api)
    elseif shapes[event.action] then
        select_shape(api, shapes[event.action])
    elseif colors[event.action] then
        select_color(api, colors[event.action])
    elseif event.action == "build.place" then
        beacon_count = beacon_count + 1
        local checkpoint = ((beacon_count - 1) % 4) + 1
        api.ui:set_text("second-game-status", "BEACON " .. checkpoint .. "/4")
    elseif event.action == "build.remove" then
        api.ui:set_text("second-game-status", "ROUTE EDITED")
    elseif event.action == "build.rotate" then
        api.ui:set_text("second-game-status", "TURN MARKER")
    end
end
-- end include: ui/actions.luau

local SecondGame = {}

function SecondGame.on_start(api)
    api.lobby:set_status("SECOND GAME: step onto DROP SIGNAL to start the relay")
    api.ui.selected_shape = "beam"
    api.ui.selected_color = "periwinkle"
    api.ui.open_popover = nil
    api.ui:set_document(GameUIDocument.create())
    api.ui:set_text("second-game-status", "DROP BEACON 0/4")
end

function SecondGame.on_ui_event(api, event)
    GameUIActions.handle(api, event)
end

function SecondGame.on_tick(_api, _delta_seconds)
    -- The relay route and its collision geometry live in the manifest. The
    -- shared host still owns movement, launch timing, and multiplayer state.
end

return SecondGame
