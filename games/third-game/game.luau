-- GENERATED FILE: do not edit; edit src/ and run cubacadabra build-game.
-- game: third-game
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
    ["@cubacadabra/disclosure"] = "@cubacadabra/disclosure",
    ["@cubacadabra/shared-state"] = "@cubacadabra/shared-state",
}
__modules["main.luau"] = function(require)
-- Capability Probe is intentionally a small, complete preview SDK example.
local CubaSharedState = require("@cubacadabra/shared-state")
local CubaDisclosure = require("@cubacadabra/disclosure")

local Game = {}

local state_store
local objective
local visits = 0
local last_sensor = "none"
local slider_value = 0.5
local operation_sequence = 0
-- This VM-local prefix is sufficient for the single-client capability probe.
-- Production games must use a host/session identity that is unique across
-- every client sharing the retained channel.
local operation_prefix = tostring({})

local function initial_state()
    return { version = 1, visits = 0, lastSensor = "none", operations = {} }
end

local function validate_state(value)
    if type(value) ~= "table"
        or value.version ~= 1
        or type(value.visits) ~= "number"
        or value.visits < 0
        or type(value.lastSensor) ~= "string"
        or type(value.operations) ~= "table"
    then
        return nil
    end
    local operations = {}
    for operation_id, accepted in pairs(value.operations) do
        if type(operation_id) == "string" and accepted == true then
            operations[operation_id] = true
        end
    end
    return {
        version = 1,
        visits = math.floor(value.visits),
        lastSensor = string.sub(value.lastSensor, 1, 32),
        operations = operations,
    }
end

local function reduce_state(state, intent)
    if intent.type ~= "visit"
        or type(intent.sensor) ~= "string"
        or type(intent.operationId) ~= "string"
    then
        return nil
    end
    if state.operations[intent.operationId] == true then
        return nil
    end
    local operations = {}
    for id, accepted in pairs(state.operations) do
        operations[id] = accepted
    end
    operations[intent.operationId] = true
    return {
        version = 1,
        visits = state.visits + 1,
        lastSensor = intent.sensor,
        operations = operations,
    }
end

local function operation_status(state, intent)
    return state.operations[intent.operationId] == true and "accepted" or "pending"
end

local function set_status(api, text)
    api.ui:set_text("probe-status", text)
    api.ui:set_text("probe-count", string.format("SHARED VISITS  %d", visits))
    api.ui:set_text("probe-sensor", "LAST SENSOR  " .. last_sensor)
    api.ui:set_value("probe-slider", slider_value)
end

local function on_state_change(api, state, previous)
    visits = state.visits
    last_sensor = state.lastSensor
    api.effects:set_state("probe-left", last_sensor == "probe-left" and "visited" or "default")
    api.effects:set_state("probe-right", last_sensor == "probe-right" and "visited" or "default")
    api.effects:set_state("probe-finish", last_sensor == "probe-finish" and "visited" or "default")
    if previous ~= nil and state.visits > previous.visits then
        api.effects:play("probe-pulse", { position = { 0, 0, 0 } })
        api.audio:play("probe-ping")
    end
    set_status(api, "ACCEPTED  " .. last_sensor)
end

state_store = CubaSharedState.create({
    channel = "probe-shared-state",
    initial = initial_state,
    validate = validate_state,
    reduce = reduce_state,
    mode = "distinct",
    operationStatus = operation_status,
    onChange = on_state_change,
})

objective = CubaDisclosure.create({
    action = "probe.objective.toggle",
    triggerId = "probe-objective",
    nodeIds = { "probe-detail" },
})

local function document()
    return {
        nodes = {
            {
                id = "probe-title",
                kind = "text",
                text = "CAPABILITY PROBE",
                layout = { anchor = "topLeft", width = 330, height = 32, offset = { 28, 126 } },
                style = { color = "#173B43", fontSize = 20 },
            },
            {
                id = "probe-status",
                kind = "text",
                text = "CONNECTING TO SHARED STATE",
                layout = { anchor = "topLeft", width = 330, height = 28, offset = { 28, 164 } },
                style = { color = "#47766F", fontSize = 14 },
            },
            {
                id = "probe-count",
                kind = "text",
                text = "SHARED VISITS  0",
                layout = { anchor = "topLeft", width = 250, height = 24, offset = { 28, 198 } },
                style = { color = "#173B43", fontSize = 12 },
            },
            {
                id = "probe-sensor",
                kind = "text",
                text = "LAST SENSOR  none",
                layout = { anchor = "topLeft", width = 280, height = 24, offset = { 28, 228 } },
                style = { color = "#173B43", fontSize = 12 },
            },
            {
                id = "probe-slider-label",
                kind = "text",
                text = "LOCAL SLIDER",
                layout = { anchor = "topLeft", width = 180, height = 22, offset = { 28, 268 } },
                style = { color = "#47766F", fontSize = 12 },
            },
            {
                id = "probe-slider",
                kind = "slider",
                value = 0.5,
                min = 0,
                max = 1,
                step = 0.05,
                action = "probe.slider",
                layout = { anchor = "topLeft", width = 230, height = 36, offset = { 28, 288 } },
            },
            {
                id = "probe-objective",
                kind = "toggle",
                text = "SHOW OBJECTIVE",
                checked = false,
                action = "probe.objective.toggle",
                layout = { anchor = "topLeft", width = 230, height = 44, offset = { 28, 338 } },
            },
            {
                id = "probe-detail",
                kind = "text",
                text = "Walk through all three sensors. Open this panel, move the slider, then clear the UI.",
                visible = false,
                layout = { anchor = "topLeft", width = 330, height = 54, offset = { 28, 394 } },
                style = { color = "#47766F", fontSize = 12 },
            },
            {
                id = "probe-clear",
                kind = "button",
                text = "CLEAR UI",
                action = "probe.clear",
                layout = { anchor = "bottom", width = 150, height = 44, offset = { 20, 20 } },
            },
        },
    }
end

function Game.on_start(api)
    api.lobby:set_enabled(false)
    api.lobby:set_status("Capability probe ready")
    api.session:start("capability-probe", { mode = "preview" })
    api.ui:set_document(document())
    objective:sync(api)
    objective:set_open(api, false)
    state_store:start(api)
    set_status(api, "WAITING FOR A SENSOR")
end

function Game.on_launch(api, launch)
    api.session:start("capability-probe:" .. launch.pad_id, {})
end

function Game.on_interaction(api, event)
    if event.phase ~= "enter" then
        return
    end
    api.network:publish("probe-events", { sensor = event.id, players = event.players })
    api.network:set_state("probe-last-event", { sensor = event.id })
    operation_sequence = operation_sequence + 1
    state_store:dispatch(api, {
        type = "visit",
        sensor = event.id,
        operationId = operation_prefix .. ":" .. tostring(operation_sequence),
    })
end

function Game.on_network_message(api, event)
    if event.channel == "probe-shared-state" then
        state_store:receive(api, event)
    elseif event.channel == "probe-events" then
        api.ui:set_text("probe-status", "EVENT  " .. event.payload.sensor)
    end
end

function Game.on_ui_event(api, event)
    if objective:handle(api, event) then
        return
    end
    if event.action == "probe.slider" and type(event.value) == "number" then
        slider_value = event.value
        api.ui:set_text("probe-status", string.format("LOCAL SLIDER  %.2f", slider_value))
        api.ui:set_checked("probe-objective", slider_value > 0.5)
    elseif event.action == "probe.clear" then
        api.ui:clear()
    end
end

function Game.on_tick(api, delta_seconds)
    state_store:update(api, delta_seconds)
    local state = api.interactions:get_state()
    for id, zone in pairs(state.zones) do
        if zone.inside then
            last_sensor = id
        end
    end
end

return Game

end
-- end module: main.luau

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
