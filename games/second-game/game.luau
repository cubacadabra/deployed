-- GENERATED FILE: do not edit; edit src/ and run cubacadabra build-game.
-- game: second-game
-- version: 0.3.0

-- Portable entry point for Signal Run.
-- All relay rules and presentation stay inside this game package.

-- begin SDK include: @cubacadabra/shared-state-v1.luau
-- Cubacadabra shared-state SDK v1.
--
-- This client-side helper keeps the backend contract generic: the server
-- orders opaque snapshots, while each game owns validation and reduction.

local CubaSharedState = {}
CubaSharedState.__index = CubaSharedState

local MAX_PENDING_INTENTS = 32
local DEFAULT_RETRY_SECONDS = 0.75

local function require_function(config, key)
    if type(config[key]) ~= "function" then
        error("CubaSharedState config." .. key .. " must be a function")
    end
end

function CubaSharedState.create(config)
    if type(config) ~= "table" then
        error("CubaSharedState.create requires a config table")
    end
    if type(config.channel) ~= "string" or #config.channel < 1 or #config.channel > 64 then
        error("CubaSharedState config.channel must be 1-64 bytes")
    end
    require_function(config, "initial")
    require_function(config, "validate")
    require_function(config, "reduce")
    if config.onChange ~= nil and type(config.onChange) ~= "function" then
        error("CubaSharedState config.onChange must be a function")
    end

    local retry_seconds = config.retrySeconds or DEFAULT_RETRY_SECONDS
    if type(retry_seconds) ~= "number" or retry_seconds <= 0 then
        error("CubaSharedState config.retrySeconds must be positive")
    end

    return setmetatable({
        channel = config.channel,
        initial = config.initial,
        validate = config.validate,
        reduce = config.reduce,
        onChange = config.onChange,
        retrySeconds = retry_seconds,
        value = nil,
        sequence = 0,
        ageSeconds = 0,
        started = false,
        hasSnapshot = false,
        bootstrapValue = nil,
        bootstrapSeconds = 0,
        pending = {},
        inflight = nil,
        inflightSeconds = 0,
    }, CubaSharedState)
end

function CubaSharedState:_drop_head()
    table.remove(self.pending, 1)
end

function CubaSharedState:_submit_next(api)
    if not self.hasSnapshot or self.inflight ~= nil then
        return
    end

    while #self.pending > 0 do
        local intent = self.pending[1]
        local next_value = self.reduce(self.value, intent)
        if next_value == nil then
            self:_drop_head()
        else
            local validated = self.validate(next_value)
            if validated == nil then
                error("CubaSharedState reducer returned an invalid state")
            end
            self.inflight = {
                intent = intent,
                expectedSequence = self.sequence,
            }
            self.inflightSeconds = 0
            api.network:compare_set_state(
                self.channel,
                self.sequence,
                validated
            )
            return
        end
    end
end

function CubaSharedState:start(api)
    if self.started then
        return
    end
    local initial_value = self.validate(self.initial())
    if initial_value == nil then
        error("CubaSharedState initial state is invalid")
    end
    self.started = true
    self.bootstrapValue = initial_value
    self.bootstrapSeconds = 0
    api.network:compare_set_state(self.channel, 0, initial_value)
end

function CubaSharedState:dispatch(api, intent)
    if type(intent) ~= "table" then
        error("CubaSharedState intents must be tables")
    end
    if #self.pending >= MAX_PENDING_INTENTS then
        return false
    end
    self.pending[#self.pending + 1] = intent
    self:_submit_next(api)
    return true
end

function CubaSharedState:receive(api, event)
    if type(event) ~= "table"
        or event.type ~= "game_state"
        or event.channel ~= self.channel
    then
        return false
    end
    if type(event.sequence) ~= "number" or event.sequence < 0 then
        return true
    end

    local next_value = self.validate(event.payload)
    if next_value == nil or event.sequence < self.sequence then
        return true
    end

    if self.hasSnapshot and event.sequence == self.sequence then
        if event.conflict == true and self.inflight ~= nil then
            self.inflight = nil
            self.inflightSeconds = 0
            self:_submit_next(api)
        end
        return true
    end

    local previous_value = self.value
    local was_initialized = self.hasSnapshot
    self.value = next_value
    self.sequence = event.sequence
    self.ageSeconds = type(event.ageMs) == "number"
        and math.max(0, event.ageMs / 1000)
        or 0
    self.hasSnapshot = true
    self.bootstrapValue = nil
    self.bootstrapSeconds = 0

    local completed_intent = nil
    if self.inflight ~= nil then
        local remaining_change = self.reduce(self.value, self.inflight.intent)
        if remaining_change == nil then
            completed_intent = self.inflight.intent
            self:_drop_head()
        end
        self.inflight = nil
        self.inflightSeconds = 0
    end

    if self.onChange ~= nil then
        self.onChange(api, self.value, previous_value, event, {
            initialized = was_initialized,
            completedIntent = completed_intent,
        })
    end
    self:_submit_next(api)
    return true
end

function CubaSharedState:update(api, delta_seconds)
    local elapsed = math.max(0, delta_seconds)
    self.ageSeconds = self.ageSeconds + elapsed
    if self.started and not self.hasSnapshot then
        self.bootstrapSeconds = self.bootstrapSeconds + elapsed
        if self.bootstrapSeconds >= self.retrySeconds then
            self.bootstrapSeconds = 0
            api.network:compare_set_state(self.channel, 0, self.bootstrapValue)
        end
        return
    end
    if self.inflight == nil then
        self:_submit_next(api)
        return
    end

    self.inflightSeconds = self.inflightSeconds + elapsed
    if self.inflightSeconds < self.retrySeconds then
        return
    end
    self.inflight = nil
    self.inflightSeconds = 0
    self:_submit_next(api)
end

-- end SDK include: @cubacadabra/shared-state-v1.luau
-- begin SDK include: @cubacadabra/disclosure-v1.luau
-- Cubacadabra disclosure SDK v1.
--
-- Keeps optional game-owned UI collapsed behind one action without imposing
-- any layout, wording, or game rules on the document.

local CubaDisclosure = {}
CubaDisclosure.__index = CubaDisclosure

local function require_name(config, key)
    local value = config[key]
    if type(value) ~= "string" or #value < 1 or #value > 64 then
        error("CubaDisclosure config." .. key .. " must be 1-64 bytes")
    end
    return value
end

function CubaDisclosure.create(config)
    if type(config) ~= "table" then
        error("CubaDisclosure.create requires a config table")
    end

    local node_ids = config.nodeIds
    if type(node_ids) ~= "table" or #node_ids < 1 or #node_ids > 32 then
        error("CubaDisclosure config.nodeIds must contain 1-32 node ids")
    end

    local copied_ids = {}
    for index, node_id in ipairs(node_ids) do
        if type(node_id) ~= "string" or #node_id < 1 or #node_id > 64 then
            error("CubaDisclosure config.nodeIds[" .. index .. "] must be 1-64 bytes")
        end
        copied_ids[index] = node_id
    end

    if config.open ~= nil and type(config.open) ~= "boolean" then
        error("CubaDisclosure config.open must be a boolean")
    end

    local trigger_id = nil
    if config.triggerId ~= nil then
        trigger_id = require_name(config, "triggerId")
    end

    return setmetatable({
        action = require_name(config, "action"),
        triggerId = trigger_id,
        nodeIds = copied_ids,
        open = config.open == true,
    }, CubaDisclosure)
end

function CubaDisclosure:set_open(api, open)
    self.open = open == true
    for _, node_id in ipairs(self.nodeIds) do
        api.ui:set_visible(node_id, self.open)
    end
    if self.triggerId ~= nil then
        api.ui:set_checked(self.triggerId, self.open)
    end
end

function CubaDisclosure:sync(api)
    self:set_open(api, self.open)
end

function CubaDisclosure:handle(api, event)
    if type(event) ~= "table"
        or event.phase ~= "activate"
        or event.action ~= self.action
    then
        return false
    end

    self:set_open(api, not self.open)
    return true
end

-- end SDK include: @cubacadabra/disclosure-v1.luau
-- begin include: relay.luau
local SignalRelay = {}
SignalRelay.__index = SignalRelay

local STATE_CHANNEL = "signal-run-round"
local OVERDRIVE_SECONDS = 5.5
local NODE_IDS = { "node-1", "node-2", "node-3", "node-4" }
local NODE_POSITIONS = {
    { -15, 0, 10 },
    { 15, 0, 1 },
    { -15, 0, -8 },
    { 15, 0, -17 },
}
local UPLINK_POSITION = { 0, 0, -31 }

local function initial_state(round, links)
    return {
        version = 1,
        round = round or 1,
        phase = "running",
        nextNode = 1,
        links = links or 0,
        lastAction = { type = "round_reset", round = round or 1 },
    }
end

local function validate_state(payload)
    if type(payload) ~= "table"
        or payload.version ~= 1
        or type(payload.round) ~= "number"
        or payload.round < 1
        or type(payload.nextNode) ~= "number"
        or payload.nextNode < 1
        or payload.nextNode > #NODE_IDS + 1
        or (payload.phase ~= "running"
            and payload.phase ~= "uplink"
            and payload.phase ~= "overdrive")
    then
        return nil
    end
    if payload.phase == "running" and payload.nextNode > #NODE_IDS then
        return nil
    end
    if payload.phase ~= "running" and payload.nextNode ~= #NODE_IDS + 1 then
        return nil
    end

    return {
        version = 1,
        round = payload.round,
        phase = payload.phase,
        nextNode = payload.nextNode,
        links = type(payload.links) == "number" and math.max(0, payload.links) or 0,
        lastAction = type(payload.lastAction) == "table" and payload.lastAction or {},
    }
end

local function reduce_state(state, intent)
    if intent.type == "capture"
        and state.phase == "running"
        and intent.node == state.nextNode
    then
        local next_node = state.nextNode + 1
        return {
            version = 1,
            round = state.round,
            phase = next_node > #NODE_IDS and "uplink" or "running",
            nextNode = next_node,
            links = state.links,
            lastAction = { type = "capture", node = intent.node },
        }
    end

    if intent.type == "uplink" and state.phase == "uplink" then
        return {
            version = 1,
            round = state.round,
            phase = "overdrive",
            nextNode = state.nextNode,
            links = state.links + 1,
            lastAction = { type = "uplink" },
        }
    end

    if intent.type == "reset"
        and state.phase == "overdrive"
        and intent.round == state.round
    then
        return initial_state(state.round + 1, state.links)
    end

    -- A nil result also makes repeated or remotely-completed intents
    -- idempotent; the SDK removes them from its queue.
    return nil
end

local function node_index(id)
    for index, node_id in ipairs(NODE_IDS) do
        if id == node_id then
            return index
        end
    end
    return nil
end

function SignalRelay.create()
    local relay = setmetatable({
        fallbackState = initial_state(),
        message = "Follow the pulsing gate. The relay is shared.",
        resetQueued = false,
    }, SignalRelay)

    relay.shared = CubaSharedState.create({
        channel = STATE_CHANNEL,
        initial = function()
            return initial_state()
        end,
        validate = validate_state,
        reduce = reduce_state,
        onChange = function(api, state, previous, event)
            relay:on_change(api, state, previous, event)
        end,
    })
    return relay
end

function SignalRelay:state()
    return self.shared.value or self.fallbackState
end

function SignalRelay:node_count()
    return #NODE_IDS
end

function SignalRelay:remaining_seconds()
    if self:state().phase ~= "overdrive" then
        return 0
    end
    return math.max(0, OVERDRIVE_SECONDS - self.shared.ageSeconds)
end

function SignalRelay:sync_effects(api, state)
    for index, id in ipairs(NODE_IDS) do
        local effect_state = "locked"
        if index < state.nextNode then
            effect_state = "captured"
        elseif state.phase == "running" and state.nextNode == index then
            effect_state = "active"
        end
        api.effects:set_state(id, effect_state)
    end

    local uplink_state = "locked"
    if state.phase == "uplink" then
        uplink_state = "active"
    elseif state.phase == "overdrive" then
        uplink_state = "overdrive"
    end
    api.effects:set_state("uplink", uplink_state)
end

function SignalRelay:on_change(api, state, previous, _event)
    if previous ~= nil then
        local captured_node = state.nextNode > previous.nextNode
            and state.nextNode - 1
            or nil
        if captured_node ~= nil and NODE_IDS[captured_node] ~= nil then
            if captured_node == 2 then
                api.audio:play("relay-chain")
            elseif captured_node == 4 then
                api.audio:play("uplink-ready")
            else
                api.audio:play("relay-hit")
            end
            api.effects:play(
                "relay-capture",
                { position = NODE_POSITIONS[captured_node] }
            )
        end
        if state.phase == "overdrive" and previous.phase ~= "overdrive" then
            api.audio:play("relay-overdrive")
            api.effects:play("overdrive-burst", { position = UPLINK_POSITION })
        end
    end

    if state.round ~= (previous and previous.round or state.round) then
        self.resetQueued = false
        self.message = "New relay! Follow node 01."
    elseif state.phase == "overdrive" then
        self.message = "Signal locked! The whole relay is live."
    elseif state.phase == "uplink" and (previous == nil or previous.phase ~= "uplink") then
        self.message = "All nodes linked! Sprint to the uplink."
    elseif state.lastAction.type == "capture"
        and type(state.lastAction.node) == "number"
    then
        self.message = string.format(
            "Node %02d linked • next node %02d",
            state.lastAction.node,
            state.nextNode
        )
    end
    self:sync_effects(api, state)
end

function SignalRelay:initialize(api)
    self.shared:start(api)
    self:sync_effects(api, self:state())
end

function SignalRelay:request_interaction(api, id)
    local state = self:state()
    if id == "uplink" then
        if state.phase == "uplink" then
            self.message = "Firing the shared uplink..."
            self.shared:dispatch(api, { type = "uplink" })
        elseif state.phase == "running" then
            self.message = string.format("UPLINK LOCKED • FIND NODE %02d", state.nextNode)
        end
        return
    end

    local index = node_index(id)
    if index == nil or state.phase ~= "running" then
        return
    end
    if index ~= state.nextNode then
        if index < state.nextNode then
            self.message = string.format("NODE %02d ALREADY LINKED", index)
        else
            self.message = string.format("NODE %02d LOCKED • FIND NODE %02d", index, state.nextNode)
        end
        return
    end

    self.message = string.format("Linking node %02d...", index)
    self.shared:dispatch(api, { type = "capture", node = index })
end

function SignalRelay:receive(api, event)
    return self.shared:receive(api, event)
end

function SignalRelay:tick(api, delta_seconds)
    self.shared:update(api, delta_seconds)
    local state = self:state()
    if state.phase == "overdrive"
        and self:remaining_seconds() <= 0
        and not self.resetQueued
    then
        self.resetQueued = true
        self.shared:dispatch(api, { type = "reset", round = state.round })
    end
end
-- end include: relay.luau
-- begin include: ui/styles.luau
local GameUIStyles = {}

GameUIStyles.colors = {
    ink = "#0B102BF0",
    paper = "#F7F5E9FF",
    quiet = "#B9C3E4FF",
    signal = "#57E5D0FF",
    hot = "#FF5B85FF",
    keyline = "#57E5D070",
}

function GameUIStyles.panel_style()
    return {
        background = GameUIStyles.colors.ink,
        borderColor = GameUIStyles.colors.keyline,
        borderWidth = 2,
        cornerRadius = 14,
        foreground = GameUIStyles.colors.paper,
    }
end

function GameUIStyles.control_style()
    return {
        background = "#151A3FE8",
        borderColor = GameUIStyles.colors.signal,
        borderWidth = 2,
        cornerRadius = 12,
        foreground = GameUIStyles.colors.paper,
        accent = GameUIStyles.colors.signal,
        textAlign = "center",
        fontSize = 14,
    }
end
-- end include: ui/styles.luau
-- begin include: ui/document.luau
local GameUIDocument = {}

function GameUIDocument.create()
    return {
        nodes = {
            {
                id = "signal-status",
                kind = "button",
                text = "NODE 01 / 04",
                action = "signal.detail.toggle",
                visibleIn = { "relay-yard" },
                layout = {
                    anchor = "topRight",
                    width = 154,
                    height = 52,
                    offset = { -18, 102 },
                },
                style = GameUIStyles.control_style(),
            },
            {
                id = "signal-detail",
                kind = "panel",
                visible = false,
                visibleIn = { "relay-yard" },
                layout = {
                    anchor = "topRight",
                    width = 280,
                    height = 96,
                    offset = { -18, 164 },
                    padding = 10,
                    direction = "column",
                    align = "stretch",
                    gap = 3,
                },
                style = GameUIStyles.panel_style(),
                children = {
                    {
                        id = "signal-kicker",
                        kind = "text",
                        text = "SIGNAL RUN • 0 LINKS",
                        layout = { width = "fill", height = 18 },
                        style = { fontSize = 12, foreground = GameUIStyles.colors.signal },
                    },
                    {
                        id = "signal-route",
                        kind = "text",
                        text = ">01<  02  03  04  UPLINK",
                        layout = { width = "fill", height = 18 },
                        style = { fontSize = 11, foreground = GameUIStyles.colors.hot },
                    },
                    {
                        id = "signal-help",
                        kind = "text",
                        text = "Follow the pulsing gate. The relay is shared.",
                        layout = { width = "fill", height = 30 },
                        style = { fontSize = 11, foreground = GameUIStyles.colors.quiet },
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
                    borderColor = "#57E5D055",
                    borderWidth = 2,
                    cornerRadius = 60,
                    accent = GameUIStyles.colors.signal,
                },
            },
            {
                id = "player-jump",
                kind = "button",
                text = "JUMP",
                action = "player.jump",
                layout = { anchor = "bottomRight", width = 86, height = 44, offset = { -22, -84 } },
                style = GameUIStyles.control_style(),
            },
            {
                id = "player-run",
                kind = "button",
                text = "RUN",
                action = "player.run",
                layout = { anchor = "bottomRight", width = 86, height = 44, offset = { -22, -30 } },
                style = GameUIStyles.control_style(),
            },
        },
    }
end
-- end include: ui/document.luau
-- begin include: ui/actions.luau
local SignalUI = {}

local function route_text(relay)
    local state = relay:state()
    local parts = {}
    for index = 1, relay:node_count() do
        local label = string.format("%02d", index)
        if index < state.nextNode then
            parts[index] = "X" .. label
        elseif state.phase == "running" and state.nextNode == index then
            parts[index] = ">" .. label .. "<"
        else
            parts[index] = label
        end
    end

    local uplink = "UPLINK"
    if state.phase == "uplink" then
        uplink = ">UPLINK<"
    elseif state.phase == "overdrive" then
        uplink = "XUPLINK"
    end
    return table.concat(parts, "  ") .. "  " .. uplink
end

function SignalUI.update(api, relay)
    local state = relay:state()
    local status
    local help = relay.message
    if state.phase == "overdrive" then
        status = "OVERDRIVE"
        help = string.format("Relay linked! Reset in %.1fs.", relay:remaining_seconds())
    elseif state.phase == "uplink" then
        status = "UPLINK OPEN"
    else
        status = string.format("NODE %02d / %02d", state.nextNode, relay:node_count())
    end

    api.ui:set_text("signal-kicker", string.format("SIGNAL RUN • %d LINKS", state.links))
    api.ui:set_text("signal-status", status)
    api.ui:set_text("signal-route", route_text(relay))
    api.ui:set_text("signal-help", help)
end
-- end include: ui/actions.luau

local SecondGame = {}
local relay = SignalRelay.create()
local signal_detail = CubaDisclosure.create({
    action = "signal.detail.toggle",
    triggerId = "signal-status",
    nodeIds = { "signal-detail" },
})

function SecondGame.on_start(api)
    api.lobby:set_status("Chain four signal gates, then fire the uplink!")
    api.ui:set_document(GameUIDocument.create())
    signal_detail:sync(api)
    relay:initialize(api)
    SignalUI.update(api, relay)
end

function SecondGame.on_interaction(api, event)
    if event.phase ~= "enter" then
        return
    end
    relay:request_interaction(api, event.id)
    SignalUI.update(api, relay)
end

function SecondGame.on_network_message(api, event)
    if relay:receive(api, event) then
        SignalUI.update(api, relay)
    end
end

function SecondGame.on_ui_event(api, event)
    signal_detail:handle(api, event)
end

function SecondGame.on_tick(api, delta_seconds)
    relay:tick(api, delta_seconds)
    SignalUI.update(api, relay)
end

return SecondGame
