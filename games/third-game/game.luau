-- GENERATED FILE: do not edit; edit src/ and run cubacadabra build-game.
-- game: third-game
-- version: 0.3.0

-- Capability Probe is intentionally a small, complete preview SDK example.
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

local Game = {}

local state_store
local objective
local visits = 0
local last_sensor = "none"
local slider_value = 0.5

local function initial_state()
    return { version = 1, visits = 0, lastSensor = "none" }
end

local function validate_state(value)
    if type(value) ~= "table"
        or value.version ~= 1
        or type(value.visits) ~= "number"
        or value.visits < 0
        or type(value.lastSensor) ~= "string"
    then
        return nil
    end
    return {
        version = 1,
        visits = math.floor(value.visits),
        lastSensor = string.sub(value.lastSensor, 1, 32),
    }
end

local function reduce_state(state, intent)
    if intent.type ~= "visit"
        or type(intent.sensor) ~= "string"
        or type(intent.expectedVisits) ~= "number"
        or intent.expectedVisits ~= math.floor(intent.expectedVisits)
    then
        return nil
    end
    -- A queued intent is complete once an authoritative snapshot advances the
    -- counter from the value observed when this visit was dispatched. This is
    -- required because the shared-state helper retries compare-and-set calls.
    if state.visits ~= intent.expectedVisits then
        return nil
    end
    return {
        version = 1,
        visits = state.visits + 1,
        lastSensor = intent.sensor,
    }
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
    state_store:dispatch(api, {
        type = "visit",
        sensor = event.id,
        expectedVisits = visits,
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
