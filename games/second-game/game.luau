-- GENERATED FILE: do not edit; edit src/ and run cubacadabra build-game.
-- game: second-game
-- version: 0.3.0

local __modules = {}
local __routes = {}
local __cache = {}
local __loading = {}

-- begin module: @cubacadabra/disclosure
__routes["@cubacadabra/disclosure"] = {
}
__modules["@cubacadabra/disclosure"] = function(require)
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

return CubaDisclosure

end
-- end module: @cubacadabra/disclosure

-- begin module: @cubacadabra/shared-state
__routes["@cubacadabra/shared-state"] = {
}
__modules["@cubacadabra/shared-state"] = function(require)
-- Cubacadabra shared-state SDK v1.
--
-- This client-side helper keeps the backend contract generic: the server
-- orders opaque snapshots, while each game owns validation and reduction.

local CubaSharedState = {}
CubaSharedState.__index = CubaSharedState

local MAX_PENDING_INTENTS = 32
local DEFAULT_RETRY_SECONDS = 0.75
local DEFAULT_MODE = "coalescing"
local DISTINCT_MODE = "distinct"
local OPERATION_STATUSES = {
    pending = true,
    accepted = true,
    rejected = true,
    expired = true,
}

local function require_function(config, key)
    if type(config[key]) ~= "function" then
        error("CubaSharedState config." .. key .. " must be a function")
    end
end

local function require_listener(listener)
    if type(listener) ~= "function" then
        error("CubaSharedState listener must be a function")
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
    local mode = config.mode or DEFAULT_MODE
    if mode ~= DEFAULT_MODE and mode ~= DISTINCT_MODE then
        error("CubaSharedState config.mode must be coalescing or distinct")
    end
    if mode == DISTINCT_MODE then
        require_function(config, "operationStatus")
    elseif config.operationStatus ~= nil then
        error("CubaSharedState config.operationStatus requires distinct mode")
    end
    if config.intentExpired ~= nil and type(config.intentExpired) ~= "function" then
        error("CubaSharedState config.intentExpired must be a function")
    end
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
        mode = mode,
        operationStatus = config.operationStatus,
        intentExpired = config.intentExpired,
        onChange = config.onChange,
        listeners = {},
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

function CubaSharedState:_operation_status(state, intent)
    if self.mode == DISTINCT_MODE then
        local status = self.operationStatus(state, intent)
        if not OPERATION_STATUSES[status] then
            error("CubaSharedState operationStatus must return pending, accepted, rejected, or expired")
        end
        return status
    end
    if self.intentExpired ~= nil then
        local expired = self.intentExpired(state, intent)
        if type(expired) ~= "boolean" then
            error("CubaSharedState intentExpired must return a boolean")
        end
        if expired then
            return "expired"
        end
    end
    return nil
end

function CubaSharedState:_has_operation_id(operation_id)
    for _, queued in ipairs(self.pending) do
        if queued.operationId == operation_id then
            return true
        end
    end
    return false
end

-- Add a consumer to the ordered state-change feed. Consumers receive the same
-- snapshot that onChange receives, after it has passed validation and after
-- the local model has advanced. This keeps presentation and other sinks from
-- having to poll or be called by the game lifecycle.
function CubaSharedState:subscribe(listener)
    require_listener(listener)
    self.listeners[#self.listeners + 1] = listener
    return listener
end

function CubaSharedState:_publish(api, state, previous, event, context)
    if self.onChange ~= nil then
        self.onChange(api, state, previous, event, context)
    end

    -- Snapshot the listener list so a consumer can subscribe while handling a
    -- change without changing the current publication's ordering.
    local listeners = {}
    for index, listener in ipairs(self.listeners) do
        listeners[index] = listener
    end
    for _, listener in ipairs(listeners) do
        listener(api, state, previous, event, context)
    end
end

function CubaSharedState:_drop_head()
    table.remove(self.pending, 1)
end

function CubaSharedState:_drop_expired_pending()
    local expired = {}
    if self.mode == DISTINCT_MODE or self.intentExpired == nil then
        return expired
    end
    while #self.pending > 0 do
        local intent = self.pending[1]
        if self:_operation_status(self.value, intent) ~= "expired" then
            break
        end
        expired[#expired + 1] = {
            intent = intent,
            status = "expired",
        }
        self:_drop_head()
    end
    return expired
end

function CubaSharedState:_submit_next(api)
    if not self.hasSnapshot or self.inflight ~= nil then
        return
    end

    while #self.pending > 0 do
        local intent = self.pending[1]
        local operation_status = self:_operation_status(self.value, intent)
        if operation_status ~= nil and operation_status ~= "pending" then
            self:_drop_head()
            -- A caller may dispatch an operation after its snapshot has
            -- already arrived. It is complete without another CAS proposal.
        else
            local next_value = self.reduce(self.value, intent)
            if next_value == nil then
                if self.mode == DISTINCT_MODE then
                    error("CubaSharedState distinct reducer returned nil for a pending operation")
                end
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
    -- Prime every projection from the model's initial proposal. This is
    -- local presentation only; the retained network snapshot remains the
    -- authority and will be published through the same feed when it arrives.
    self:_publish(api, initial_value, nil, {
        type = "game_state",
        channel = self.channel,
        sequence = 0,
        payload = initial_value,
        bootstrap = true,
    }, {
        initialized = false,
        completedIntent = nil,
        completedStatus = nil,
        expiredIntents = {},
        source = "initial",
    })
    api.network:compare_set_state(self.channel, 0, initial_value)
end

function CubaSharedState:dispatch(api, intent)
    if type(intent) ~= "table" then
        error("CubaSharedState intents must be tables")
    end
    if self.mode == DISTINCT_MODE then
        if type(intent.operationId) ~= "string"
            or #intent.operationId < 1
            or #intent.operationId > 128
        then
            error("CubaSharedState distinct intents require a 1-128 byte operationId")
        end
        if self:_has_operation_id(intent.operationId) then
            return true
        end
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
    local completed_status = nil
    if self.inflight ~= nil then
        local operation_status = self:_operation_status(self.value, self.inflight.intent)
        local complete = operation_status ~= nil
            and operation_status ~= "pending"
        if operation_status == nil then
            complete = self.reduce(self.value, self.inflight.intent) == nil
        end
        if complete then
            completed_intent = self.inflight.intent
            completed_status = operation_status or "accepted"
            self:_drop_head()
        end
        self.inflight = nil
        self.inflightSeconds = 0
    end
    local expired_intents = self:_drop_expired_pending()

    self:_publish(api, self.value, previous_value, event, {
        initialized = was_initialized,
        completedIntent = completed_intent,
        completedStatus = completed_status,
        expiredIntents = expired_intents,
        source = "network",
    })
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

return CubaSharedState

end
-- end module: @cubacadabra/shared-state

-- begin module: main.luau
__routes["main.luau"] = {
    ["./relay"] = "relay.luau",
    ["./ui/actions"] = "ui/actions.luau",
    ["./ui/document"] = "ui/document.luau",
    ["@cubacadabra/disclosure"] = "@cubacadabra/disclosure",
}
__modules["main.luau"] = function(require)
-- Portable entry point for Signal Run.
-- All relay rules and presentation stay inside this game package.

local CubaDisclosure = require("@cubacadabra/disclosure")
local SignalRelay = require("./relay")
local GameUIDocument = require("./ui/document")
local SignalUI = require("./ui/actions")

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
    SignalUI.bind(relay)
    relay:initialize(api)
end

function SecondGame.on_interaction(api, event)
    if event.phase ~= "enter" then
        return
    end
    relay:request_interaction(api, event.id)
end

function SecondGame.on_network_message(api, event)
    relay:receive(api, event)
end

function SecondGame.on_ui_event(api, event)
    signal_detail:handle(api, event)
end

function SecondGame.on_tick(api, delta_seconds)
    relay:tick(api, delta_seconds)
end

return SecondGame

end
-- end module: main.luau

-- begin module: relay.luau
__routes["relay.luau"] = {
    ["@cubacadabra/shared-state"] = "@cubacadabra/shared-state",
}
__modules["relay.luau"] = function(require)
local CubaSharedState = require("@cubacadabra/shared-state")

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
local INTERACTION_ZONE_SCHEMA = "cuba:interaction-zone.v1"

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
        and intent.round == state.round
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

    if intent.type == "uplink"
        and state.phase == "uplink"
        and intent.round == state.round
    then
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
        schema = nil,
    }, SignalRelay)

    relay.shared = CubaSharedState.create({
        channel = STATE_CHANNEL,
        initial = function()
            return initial_state()
        end,
        validate = validate_state,
        reduce = reduce_state,
        intentExpired = function(state, intent)
            return intent.round ~= state.round
        end,
        onChange = function(api, state, previous, event)
            relay:on_change(api, state, previous, event)
        end,
    })
    relay.shared:subscribe(function(api, state)
        -- Effects are a DataModel consumer. They react to accepted snapshots
        -- instead of being pushed from interaction or tick code.
        relay:sync_effects(api, state)
    end)
    return relay
end

function SignalRelay:state()
    return self.shared.value or self.fallbackState
end

function SignalRelay:node_count()
    return #NODE_IDS
end

function SignalRelay:node_id(index)
    return NODE_IDS[index]
end

function SignalRelay:schema_summary()
    if self.schema == nil then
        return "ENGINE SCHEMA UNAVAILABLE"
    end

    local fields = {}
    for _, property in ipairs(self.schema.properties) do
        if property.id == "cuba:interaction-zone.label"
            or property.id == "cuba:interaction-zone.radius"
        then
            fields[#fields + 1] = property.name
        end
    end
    return string.format(
        "ENGINE %s • %s",
        self.schema.name,
        table.concat(fields, " / ")
    )
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
end

function SignalRelay:initialize(api)
    self.schema = api.interactions:get_schema(INTERACTION_ZONE_SCHEMA)
    self.shared:start(api)
end

function SignalRelay:subscribe(listener)
    return self.shared:subscribe(listener)
end

function SignalRelay:request_interaction(api, id)
    local state = self:state()
    if id == "uplink" then
        if state.phase == "uplink" then
            self.shared:dispatch(api, { type = "uplink", round = state.round })
        end
        return
    end

    local index = node_index(id)
    if index == nil or state.phase ~= "running" then
        return
    end
    if index ~= state.nextNode then
        return
    end

    self.shared:dispatch(api, { type = "capture", node = index, round = state.round })
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

return SignalRelay

end
-- end module: relay.luau

-- begin module: ui/actions.luau
__routes["ui/actions.luau"] = {
}
__modules["ui/actions.luau"] = function(require)
local SignalUI = {}

local function route_text(state, node_count)
    local parts = {}
    for index = 1, node_count do
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

function SignalUI.update(api, relay, state)
    local status
    local help = relay.message
    if state.phase == "overdrive" then
        status = "OVERDRIVE"
        help = "Relay linked! The whole relay is live."
    elseif state.phase == "uplink" then
        status = "UPLINK OPEN"
    else
        status = string.format("NODE %02d / %02d", state.nextNode, relay:node_count())
    end

    api.ui:set_text("signal-kicker", string.format("SIGNAL RUN • %d LINKS", state.links))
    api.ui:set_text("signal-status", status)
    api.ui:set_text("signal-route", route_text(state, relay:node_count()))
    api.ui:set_text("signal-help", help)
    api.ui:set_text("signal-schema", relay:schema_summary())
end

function SignalUI.bind(relay)
    relay:subscribe(function(api, state)
        SignalUI.update(api, relay, state)
    end)
end

return SignalUI

end
-- end module: ui/actions.luau

-- begin module: ui/document.luau
__routes["ui/document.luau"] = {
    ["./styles"] = "ui/styles.luau",
}
__modules["ui/document.luau"] = function(require)
local GameUIStyles = require("./styles")

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
                    height = 116,
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
                        layout = { width = "fill", height = 28 },
                        style = { fontSize = 11, foreground = GameUIStyles.colors.quiet },
                    },
                    {
                        id = "signal-schema",
                        kind = "text",
                        text = "ENGINE InteractionZone • Label / Radius",
                        layout = { width = "fill", height = 18 },
                        style = { fontSize = 10, foreground = GameUIStyles.colors.signal },
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

return GameUIDocument

end
-- end module: ui/document.luau

-- begin module: ui/styles.luau
__routes["ui/styles.luau"] = {
}
__modules["ui/styles.luau"] = function(require)
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

return GameUIStyles

end
-- end module: ui/styles.luau

local function __require(module_id)
    local cached = __cache[module_id]
    if cached ~= nil then
        return cached
    end
    if __loading[module_id] then
        error("cyclic bundled require: " .. module_id)
    end
    local loader = __modules[module_id]
    if loader == nil then
        error("bundled module not found: " .. module_id)
    end
    local routes = __routes[module_id]
    local function module_require(path)
        local dependency_id = routes[path]
        if dependency_id == nil then
            error("undeclared bundled require from " .. module_id .. ": " .. tostring(path))
        end
        return __require(dependency_id)
    end
    __loading[module_id] = true
    local result = loader(module_require)
    __loading[module_id] = nil
    if result == nil then
        error("bundled module returned nil: " .. module_id)
    end
    __cache[module_id] = result
    return result
end

return __require("main.luau")
