-- GENERATED FILE: do not edit; edit src/ and run cubacadabra build-game.
-- game: first-game
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
    ["./round"] = "round.luau",
    ["./ui/actions"] = "ui/actions.luau",
    ["./ui/document"] = "ui/document.luau",
    ["@cubacadabra/disclosure"] = "@cubacadabra/disclosure",
}
__modules["main.luau"] = function(require)
-- Portable entry point for the first-game package.
-- The build step bundles this module graph into one sandboxed Luau chunk.

local CubaDisclosure = require("@cubacadabra/disclosure")
local SpellboundRound = require("./round")
local GameUIDocument = require("./ui/document")
local GameUIActions = require("./ui/actions")

local FirstGame = {}

local charm_order = { "spark", "splash", "sprout" }
local charm_names = {
    spark = "Spark",
    splash = "Splash",
    sprout = "Sprout",
}

local round = SpellboundRound.create(charm_order)
local objective = CubaDisclosure.create({
    action = "school.objective.toggle",
    triggerId = "school-objective",
    nodeIds = { "school-detail" },
})

local function update_hud(api)
    local state = api.interactions:get_state()
    local charms_learned = round:count(round.learned)
    local circle = state.zones["wand-circle"]
    local players = circle and circle.players or 1

    local status
    local help
    if round.phase == "celebrating" then
        status = "RAINBOW BURST!"
        help = string.format("Amazing teamwork! Next round in %.1fs.", round.celebrationSeconds)
    elseif round.phase == "collecting" then
        status = string.format("%d/3 charms learned", charms_learned)
        help = round.message
    elseif not (circle and circle.inside) then
        status = "All charms learned!"
        help = "Run to the Wand Circle and get ready to cast."
    else
        status = string.format("Wand Circle • %d wizard%s", players, players == 1 and "" or "s")
        help = round.message
    end

    api.ui:set_text("school-status", status)
    api.ui:set_text("school-help-text", help)
    api.ui:set_text("school-kicker", string.format("SPELLBOUND SCHOOLYARD • %d BURSTS", round.bursts))
    if round.phase == "celebrating" then
        api.ui:set_text("school-objective", "RAINBOW!")
    elseif round.phase == "collecting" then
        api.ui:set_text("school-objective", string.format("CHARMS %d/3", charms_learned))
    elseif not (circle and circle.inside) then
        api.ui:set_text("school-objective", "WAND CIRCLE")
    else
        api.ui:set_text("school-objective", "CAST CHARMS")
    end
    local show_charm_dock = round.phase == "casting" and circle ~= nil and circle.inside
    if show_charm_dock then
        objective:set_open(api, false)
    end
    api.ui:set_visible("school-objective", not show_charm_dock)
    api.ui:set_visible("charm-dock", show_charm_dock)

    for _, id in ipairs(charm_order) do
        api.ui:set_visible("charm-" .. id, round.learned[id] == true and round.cast[id] ~= true)
        api.ui:set_checked("charm-" .. id, round.cast[id] == true)
    end
end

function FirstGame.on_start(api)
    api.lobby:set_status("Learn three charms and make a rainbow burst!")
    api.ui:set_document(GameUIDocument.create())
    objective:sync(api)
    round:initialize(api)
    update_hud(api)
end

function FirstGame.on_interaction(api, event)
    if event.phase ~= "enter" or charm_names[event.id] == nil then
        return
    end
    round:request_learn(api, event.id)
end

function FirstGame.on_network_message(api, event)
    if event.type ~= "game_state" or event.channel ~= "schoolyard-round" then
        return
    end
    round:apply_snapshot(api, event)
end

function FirstGame.on_ui_event(api, event)
    if objective:handle(api, event) then
        return
    end
    GameUIActions.handle(api, event, round)
end

function FirstGame.on_tick(api, delta_seconds)
    round:tick(api, delta_seconds)

    if round.phase == "casting" and not round.circleReadyAnnounced then
        local state = api.interactions:get_state()
        local circle = state.zones["wand-circle"]
        if circle and circle.inside then
            round.circleReadyAnnounced = true
            round.message = "Wands ready! Cast the remaining charms together."
            api.audio:play("circle-ready")
        end
    end

    update_hud(api)
end

return FirstGame

end
-- end module: main.luau

-- begin module: round.luau
__routes["round.luau"] = {
    ["@cubacadabra/shared-state"] = "@cubacadabra/shared-state",
}
__modules["round.luau"] = function(require)
local CubaSharedState = require("@cubacadabra/shared-state")

local SpellboundRound = {}
SpellboundRound.__index = SpellboundRound

local STATE_CHANNEL = "schoolyard-round"
local CELEBRATION_SECONDS = 4.5
local BURST_POSITION = { 0, 0, 0 }

local function copy_flags(source, ids, allowed)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for _, id in ipairs(ids) do
        if source[id] == true and (allowed == nil or allowed[id]) then
            result[id] = true
        end
    end
    return result
end

local function all_flags(values, ids)
    for _, id in ipairs(ids) do
        if not values[id] then
            return false
        end
    end
    return true
end

local function initial_state(round, bursts)
    return {
        version = 1,
        round = round or 1,
        phase = "collecting",
        learned = {},
        cast = {},
        bursts = bursts or 0,
        lastAction = { type = "round_reset", round = round or 1 },
    }
end

local function validator_for(charm_order)
    return function(payload)
        if type(payload) ~= "table"
            or payload.version ~= 1
            or type(payload.round) ~= "number"
            or payload.round < 1
            or (payload.phase ~= "collecting"
                and payload.phase ~= "casting"
                and payload.phase ~= "celebrating")
        then
            return nil
        end

        local learned = copy_flags(payload.learned, charm_order)
        local cast = copy_flags(payload.cast, charm_order, learned)
        if payload.phase ~= "collecting" and not all_flags(learned, charm_order) then
            return nil
        end
        if payload.phase == "celebrating" and not all_flags(cast, charm_order) then
            return nil
        end
        return {
            version = 1,
            round = payload.round,
            phase = payload.phase,
            learned = learned,
            cast = cast,
            bursts = type(payload.bursts) == "number" and math.max(0, payload.bursts) or 0,
            lastAction = type(payload.lastAction) == "table" and payload.lastAction or {},
        }
    end
end

local function reducer_for(charm_order)
    return function(state, intent)
        if intent.type == "learn"
            and state.phase == "collecting"
            and intent.round == state.round
            and not state.learned[intent.charm]
        then
            local learned = copy_flags(state.learned, charm_order)
            learned[intent.charm] = true
            return {
                version = 1,
                round = state.round,
                phase = all_flags(learned, charm_order) and "casting" or "collecting",
                learned = learned,
                cast = copy_flags(state.cast, charm_order, learned),
                bursts = state.bursts,
                lastAction = { type = "learn", charm = intent.charm },
            }
        end

        if intent.type == "cast"
            and state.phase == "casting"
            and intent.round == state.round
            and state.learned[intent.charm]
            and not state.cast[intent.charm]
        then
            local cast = copy_flags(state.cast, charm_order, state.learned)
            cast[intent.charm] = true
            local celebrating = all_flags(cast, charm_order)
            return {
                version = 1,
                round = state.round,
                phase = celebrating and "celebrating" or "casting",
                learned = copy_flags(state.learned, charm_order),
                cast = cast,
                bursts = state.bursts + (celebrating and 1 or 0),
                lastAction = { type = "cast", charm = intent.charm },
            }
        end

        if intent.type == "reset"
            and state.phase == "celebrating"
            and intent.round == state.round
        then
            return initial_state(state.round + 1, state.bursts)
        end
        return nil
    end
end

function SpellboundRound.create(charm_order)
    local round = setmetatable({
        charmOrder = charm_order,
        round = 1,
        phase = "collecting",
        learned = {},
        cast = {},
        bursts = 0,
        celebrationSeconds = 0,
        circleReadyAnnounced = false,
        message = "Find the three beginner charms.",
        resetQueued = false,
    }, SpellboundRound)

    round.shared = CubaSharedState.create({
        channel = STATE_CHANNEL,
        initial = function()
            return initial_state()
        end,
        validate = validator_for(charm_order),
        reduce = reducer_for(charm_order),
        intentExpired = function(state, intent)
            return intent.round ~= state.round
        end,
        onChange = function(api, state, previous, event)
            round:on_change(api, state, previous, event)
        end,
    })
    return round
end

function SpellboundRound:count(values)
    local total = 0
    for _, id in ipairs(self.charmOrder) do
        if values[id] then
            total = total + 1
        end
    end
    return total
end

function SpellboundRound:all_learned()
    return all_flags(self.learned, self.charmOrder)
end

function SpellboundRound:all_cast()
    return all_flags(self.cast, self.charmOrder)
end

function SpellboundRound:sync_state(state)
    self.round = state.round
    self.phase = state.phase
    self.learned = state.learned
    self.cast = state.cast
    self.bursts = state.bursts
end

function SpellboundRound:on_change(api, state, previous, _event)
    if previous ~= nil then
        for _, id in ipairs(self.charmOrder) do
            if state.learned[id] and not previous.learned[id] then
                api.audio:play("charm-learned")
            end
            if state.cast[id] and not previous.cast[id] then
                api.audio:play("spell-cast")
            end
        end
        if state.phase == "celebrating" and previous.phase ~= "celebrating" then
            api.audio:play("rainbow-burst")
            api.effects:play("rainbow-burst", { position = BURST_POSITION })
        end
    end

    self:sync_state(state)
    for _, id in ipairs(self.charmOrder) do
        api.effects:set_state(id, self.learned[id] and "collected" or "available")
    end
    api.effects:set_state("wand-circle", self.phase)

    if previous ~= nil and state.round ~= previous.round then
        self.resetQueued = false
        self.circleReadyAnnounced = false
        self.message = "A new round! Find the three beginner charms."
    elseif self.phase == "celebrating" then
        self.message = "You made a rainbow burst with your friends!"
    elseif state.lastAction.type == "learn" then
        self.message = string.upper(state.lastAction.charm or "CHARM")
            .. " learned by your spell circle!"
    elseif state.lastAction.type == "cast" then
        self.message = string.upper(state.lastAction.charm or "CHARM")
            .. " joined the shared burst!"
    elseif self.phase == "casting" and (previous == nil or previous.phase ~= "casting") then
        self.message = "All charms learned! Meet in the Wand Circle."
    end
    self.celebrationSeconds = self.phase == "celebrating"
        and math.max(0, CELEBRATION_SECONDS - self.shared.ageSeconds)
        or 0
end

function SpellboundRound:initialize(api)
    self.shared:start(api)
end

function SpellboundRound:request_learn(api, charm)
    if self.phase ~= "collecting" or self.learned[charm] then
        return
    end
    self.message = "Learning " .. string.upper(charm) .. "..."
    self.shared:dispatch(api, { type = "learn", charm = charm, round = self.round })
end

function SpellboundRound:request_cast(api, charm)
    if self.phase ~= "casting" or not self.learned[charm] or self.cast[charm] then
        return
    end
    self.message = "Casting " .. string.upper(charm) .. "..."
    self.shared:dispatch(api, { type = "cast", charm = charm, round = self.round })
end

function SpellboundRound:apply_snapshot(api, event)
    self.shared:receive(api, event)
end

function SpellboundRound:tick(api, delta_seconds)
    self.shared:update(api, delta_seconds)
    self.celebrationSeconds = self.phase == "celebrating"
        and math.max(0, CELEBRATION_SECONDS - self.shared.ageSeconds)
        or 0
    if self.phase == "celebrating"
        and self.celebrationSeconds <= 0
        and not self.resetQueued
    then
        self.resetQueued = true
        self.shared:dispatch(api, { type = "reset", round = self.round })
    end
end

return SpellboundRound

end
-- end module: round.luau

-- begin module: ui/actions.luau
__routes["ui/actions.luau"] = {
}
__modules["ui/actions.luau"] = function(require)
local GameUIActions = {}

function GameUIActions.handle(api, event, round)
    if event.phase ~= "activate" then
        return
    end
    local prefix = "charm.cast."
    if string.sub(event.action, 1, #prefix) ~= prefix then
        return
    end

    local id = string.sub(event.action, #prefix + 1)
    if round.learned[id] and not round.cast[id] then
        round:request_cast(api, id)
        api.ui:set_checked("charm-" .. id, false)
    else
        api.ui:set_checked("charm-" .. id, round.cast[id] == true)
    end
end

return GameUIActions

end
-- end module: ui/actions.luau

-- begin module: ui/document.luau
__routes["ui/document.luau"] = {
    ["./styles"] = "ui/styles.luau",
}
__modules["ui/document.luau"] = function(require)
local GameUIStyles = require("./styles")

local GameUIDocument = {}

local function charm_button(id, label, color)
    return {
        id = "charm-" .. id,
        kind = "button",
        text = label,
        action = "charm.cast." .. id,
        visible = false,
        visibleIn = { "schoolyard" },
        layout = { width = 104, height = 56 },
        style = GameUIStyles.charm_style(color),
    }
end

function GameUIDocument.create()
    return {
        nodes = {
            {
                id = "school-objective",
                kind = "button",
                text = "CHARMS 0/3",
                action = "school.objective.toggle",
                visibleIn = { "schoolyard" },
                layout = {
                    region = "bottomCenter",
                    width = 104,
                    height = 56,
                },
                style = GameUIStyles.control_style(
                    GameUIStyles.colors.ink,
                    GameUIStyles.colors.rainbow,
                    GameUIStyles.colors.paper,
                    18
                ),
            },
            {
                id = "school-detail",
                kind = "panel",
                visible = false,
                visibleIn = { "schoolyard" },
                layout = {
                    anchor = "topRight",
                    width = 276,
                    height = 112,
                    offset = { -18, 102 },
                    padding = 10,
                    direction = "column",
                    align = "stretch",
                    gap = 3,
                },
                style = GameUIStyles.panel_style(),
                children = {
                    {
                        id = "school-kicker",
                        kind = "text",
                        text = "SPELLBOUND SCHOOLYARD",
                        layout = { width = "fill", height = 18 },
                        style = { fontSize = 12, foreground = GameUIStyles.colors.rainbow },
                    },
                    {
                        id = "school-status",
                        kind = "text",
                        text = "Find the three beginner charms.",
                        layout = { width = "fill", height = 20 },
                        style = { fontSize = 14, foreground = GameUIStyles.colors.paper },
                    },
                    {
                        id = "school-help-text",
                        kind = "text",
                        text = "Walk into a glowing spot to learn its charm.",
                        layout = { width = "fill", height = 36 },
                        style = { fontSize = 12, foreground = GameUIStyles.colors.quiet },
                    },
                },
            },
            {
                id = "charm-dock",
                kind = "panel",
                visible = false,
                visibleIn = { "schoolyard" },
                layout = {
                    region = "bottomCenter",
                    width = 344,
                    height = 64,
                    padding = 4,
                    direction = "row",
                    align = "center",
                    justify = "center",
                    gap = 6,
                },
                style = GameUIStyles.panel_style("#17304AF2", 22),
                children = {
                    charm_button("spark", "SPARK", GameUIStyles.colors.spark),
                    charm_button("splash", "SPLASH", GameUIStyles.colors.splash),
                    charm_button("sprout", "SPROUT", GameUIStyles.colors.sprout),
                },
            },
            {
                id = "player-joystick",
                kind = "joystick",
                action = "player.move",
                layout = { anchor = "bottomLeft", width = 120, height = 120, offset = { 20, -24 } },
                style = {
                    background = "#17304AC9",
                    borderColor = "#FFFDF455",
                    borderWidth = 2,
                    cornerRadius = 60,
                    accent = GameUIStyles.colors.paper,
                },
            },
            {
                id = "player-jump",
                kind = "button",
                text = "JUMP",
                action = "player.jump",
                layout = { anchor = "bottomRight", width = 86, height = 44, offset = { -22, -84 } },
                style = GameUIStyles.control_style(GameUIStyles.colors.inkRaised, GameUIStyles.colors.rainbow),
            },
            {
                id = "player-run",
                kind = "button",
                text = "RUN",
                action = "player.run",
                layout = { anchor = "bottomRight", width = 86, height = 44, offset = { -22, -30 } },
                style = GameUIStyles.control_style(GameUIStyles.colors.inkRaised, GameUIStyles.colors.rainbow),
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
    ink = "#101329F2",
    inkRaised = "#1A1D3BF5",
    paper = "#FFF8EFFF",
    quiet = "#C5C9E8FF",
    rainbow = "#FF8BB7FF",
    spark = "#FFB84DFF",
    splash = "#50C9E8FF",
    sprout = "#75D68AFF",
    keyline = "#F6E8C66B",
}

function GameUIStyles.panel_style(background, radius)
    return {
        background = background or GameUIStyles.colors.ink,
        borderColor = GameUIStyles.colors.keyline,
        borderWidth = 2,
        cornerRadius = radius or 18,
        foreground = GameUIStyles.colors.paper,
    }
end
function GameUIStyles.charm_style(color)
    return {
        background = GameUIStyles.colors.inkRaised,
        borderColor = color,
        borderWidth = 3,
        cornerRadius = 18,
        foreground = GameUIStyles.colors.paper,
        accent = color,
        textAlign = "center",
        fontSize = 13,
    }
end

function GameUIStyles.control_style(background, accent, foreground, radius)
    return {
        background = background or GameUIStyles.colors.inkRaised,
        borderColor = accent or GameUIStyles.colors.rainbow,
        borderWidth = 2,
        cornerRadius = radius or 17,
        foreground = foreground or GameUIStyles.colors.paper,
        accent = accent or GameUIStyles.colors.rainbow,
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
