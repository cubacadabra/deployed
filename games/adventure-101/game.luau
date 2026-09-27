-- GENERATED FILE: do not edit; edit src/ and run cubacadabra build-game.
-- game: adventure-101
-- version: 0.4.6

local __modules = {}
local __routes = {}
local __cache = {}
local __loading = {}

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

-- begin module: @cubacadabra/survival
__routes["@cubacadabra/survival"] = {
}
__modules["@cubacadabra/survival"] = function(require)
-- Cubacadabra survival SDK v1.
--
-- The runtime owns health, hazards, fall detection, and respawn. This helper
-- keeps the small amount of game-owned lifecycle state that most survival
-- games need without prescribing a particular objective or HUD.

local CubaSurvival = {}
CubaSurvival.__index = CubaSurvival
local LIVE_STATE_CHANNEL = "__player_state"

local function publish_state(api, survival)
    if type(api) ~= "table"
        or type(api.network) ~= "table"
        or type(api.network.publish) ~= "function" then
        return
    end
    api.network:publish(LIVE_STATE_CHANNEL, {
        kind = "survival",
        health = survival.health,
        maxHealth = survival.max_health,
        deaths = survival.deaths,
        alive = survival.state ~= "dead",
    })
end

function CubaSurvival.create(config)
    if type(config) ~= "table" then
        error("CubaSurvival.create requires a config table")
    end
    return setmetatable({
        health = 0,
        max_health = 0,
        deaths = 0,
        state = "waiting",
        source = nil,
        onSpawn = config.onSpawn,
        onDamage = config.onDamage,
        onHeal = config.onHeal,
        onDeath = config.onDeath,
        onRespawn = config.onRespawn,
    }, CubaSurvival)
end

function CubaSurvival:handle(api, event)
    if type(event) ~= "table" or type(event.kind) ~= "string" then
        return false
    end
    if event.kind == "spawn" then
        self.health = event.health or self.health
        self.max_health = event.maxHealth or self.max_health
        self.deaths = event.deaths or self.deaths
        self.source = nil
        self.state = "running"
        if type(self.onSpawn) == "function" then
            self.onSpawn(api, event, self)
        end
        publish_state(api, self)
        return true
    elseif event.kind == "damage" then
        self.health = event.health or self.health
        self.max_health = event.maxHealth or self.max_health
        self.source = event.source or self.source
        self.state = "running"
        if type(self.onDamage) == "function" then
            self.onDamage(api, event, self)
        end
        publish_state(api, self)
        return true
    elseif event.kind == "heal" then
        self.health = event.health or self.health
        self.max_health = event.maxHealth or self.max_health
        self.source = event.source or self.source
        self.state = "running"
        if type(self.onHeal) == "function" then
            self.onHeal(api, event, self)
        end
        publish_state(api, self)
        return true
    elseif event.kind == "death" then
        self.health = event.health or 0
        self.max_health = event.maxHealth or self.max_health
        self.deaths = event.deaths or self.deaths
        self.state = "dead"
        if type(self.onDeath) == "function" then
            self.onDeath(api, event, self)
        end
        publish_state(api, self)
        return true
    elseif event.kind == "respawn" then
        self.health = event.health or self.max_health
        self.max_health = event.maxHealth or self.max_health
        self.deaths = event.deaths or self.deaths
        self.source = nil
        self.state = "running"
        if type(self.onRespawn) == "function" then
            self.onRespawn(api, event, self)
        end
        publish_state(api, self)
        return true
    end
    return false
end

function CubaSurvival:status()
    return {
        state = self.state,
        health = self.health,
        maxHealth = self.max_health,
        deaths = self.deaths,
        source = self.source,
    }
end

return CubaSurvival

end
-- end module: @cubacadabra/survival

-- begin module: main.luau
__routes["main.luau"] = {
    ["@cubacadabra/shared-state"] = "@cubacadabra/shared-state",
    ["@cubacadabra/survival"] = "@cubacadabra/survival",
}
__modules["main.luau"] = function(require)
-- Whispering Wilds is the exploration/adventure reference game.
-- The manifest owns terrain, climbing, gravity, checkpoints, and hazards.
-- This script owns the shared discovery trail and the compact adventure HUD.
-- Wolves are world-owned ambient NPCs from the platform presence layer.

local CubaSurvival = require("@cubacadabra/survival")
local CubaSharedState = require("@cubacadabra/shared-state")

local Game = {}

local survival = CubaSurvival.create({})
local status = "FOLLOW THE TRAIL  •  FIND THE WATCHTOWER"
local nearby_zone = nil
local elapsed = 0

local LANDMARKS = {
    { id = "trailhead", label = "TRAILHEAD" },
    { id = "creek", label = "CREEK" },
    { id = "watchtower", label = "WATCHTOWER" },
    { id = "hollow", label = "HOLLOW" },
    { id = "relic", label = "RELIC" },
}

local function initial_trail()
    return {
        version = 1,
        discovered = {},
        relic = false,
    }
end

local function copy_discovered(value)
    local result = {}
    for key, item in pairs(value or {}) do
        result[key] = item == true
    end
    return result
end

local function validate_trail(value)
    if type(value) ~= "table" or type(value.discovered) ~= "table" then
        return nil
    end
    return {
        version = 1,
        discovered = copy_discovered(value.discovered),
        relic = value.relic == true,
    }
end

local function reduce_trail(state, intent)
    if type(intent) ~= "table" or intent.kind ~= "discover" then
        return nil
    end
    local id = intent.id
    if type(id) ~= "string" then
        return nil
    end
    local known = false
    for _, landmark in ipairs(LANDMARKS) do
        if landmark.id == id then
            known = true
            break
        end
    end
    if not known or state.discovered[id] == true then
        return nil
    end
    local next_state = {
        version = 1,
        discovered = copy_discovered(state.discovered),
        relic = state.relic,
    }
    next_state.discovered[id] = true
    next_state.relic = id == "relic" or state.relic
    return next_state
end

local trail = CubaSharedState.create({
    channel = "whispering-wilds-trail",
    initial = initial_trail,
    validate = validate_trail,
    reduce = reduce_trail,
})

local function trail_value()
    return trail.value or initial_trail()
end

local function discovery_count(state)
    local count = 0
    for _, landmark in ipairs(LANDMARKS) do
        if state.discovered[landmark.id] == true then
            count = count + 1
        end
    end
    return count
end

local function landmark_text(state)
    local result = ""
    for index, landmark in ipairs(LANDMARKS) do
        if index > 1 then
            result = result .. "  •  "
        end
        result = result .. (state.discovered[landmark.id] and "✓ " or "○ ") .. landmark.label
    end
    return result
end

local function player_controls()
    return {
        nodes = {
            {
                id = "adventure-title",
                kind = "text",
                text = "WHISPERING WILDS",
                layout = { anchor = "topLeft", width = 420, height = 30, offset = { 26, 122 } },
                style = { color = "#F4F0DF", fontSize = 20 },
            },
            {
                id = "adventure-status",
                kind = "text",
                text = status,
                layout = { anchor = "topLeft", width = 620, height = 26, offset = { 26, 158 } },
                style = { color = "#F2C86B", fontSize = 14 },
            },
            {
                id = "adventure-discoveries",
                kind = "text",
                text = "DISCOVERIES 0 / 5",
                layout = { anchor = "topLeft", width = 520, height = 22, offset = { 26, 190 } },
                style = { color = "#86A9A0", fontSize = 12 },
            },
            {
                id = "adventure-landmarks",
                kind = "text",
                text = "○ TRAILHEAD  •  ○ CREEK  •  ○ WATCHTOWER",
                layout = { anchor = "topLeft", width = 760, height = 22, offset = { 26, 218 } },
                style = { color = "#F4F0DF", fontSize = 11 },
            },
            {
                id = "adventure-health",
                kind = "text",
                text = "HEALTH  -- / --   WILDLIFE  ACTIVE",
                layout = { anchor = "topLeft", width = 420, height = 22, offset = { 26, 246 } },
                style = { color = "#E77A62", fontSize = 12 },
            },
            {
                id = "adventure-help",
                kind = "text",
                text = "MOVE  •  JUMP  •  CLIMB THE WATCHTOWER  •  SEARCH THE LANDMARKS",
                layout = { anchor = "bottom", width = "90%", maxWidth = 760, height = 24, offset = { 0, -24 } },
                style = { color = "#F4F0DFB8", fontSize = 11, textAlign = "center" },
            },
            {
                id = "player-joystick",
                kind = "joystick",
                action = "player.move",
                layout = { anchor = "bottomLeft", width = 120, height = 120, offset = { 20, -24 } },
                style = { background = "#101A22D9", borderColor = "#F2C86B55", borderWidth = 2, cornerRadius = 60, accent = "#F2C86B" },
            },
            {
                id = "player-jump",
                kind = "button",
                text = "JUMP",
                action = "player.jump",
                layout = { anchor = "bottomRight", width = 86, height = 44, offset = { -22, -84 } },
                style = { background = "#101A22F5", borderColor = "#86A9A0", borderWidth = 2, cornerRadius = 17, foreground = "#F4F0DF", accent = "#86A9A0", textAlign = "center", fontSize = 14 },
            },
            {
                id = "player-run",
                kind = "button",
                text = "RUN",
                action = "player.run",
                layout = { anchor = "bottomRight", width = 86, height = 44, offset = { -22, -30 } },
                style = { background = "#101A22F5", borderColor = "#86A9A0", borderWidth = 2, cornerRadius = 17, foreground = "#F4F0DF", accent = "#86A9A0", textAlign = "center", fontSize = 14 },
            },
        },
    }
end

local function update_hud(api)
    local state = trail_value()
    local snapshot = survival:status()
    api.ui:set_text("adventure-status", status)
    api.ui:set_text("adventure-discoveries", "DISCOVERIES " .. tostring(discovery_count(state)) .. " / 5")
    api.ui:set_text("adventure-landmarks", landmark_text(state))
    if snapshot.maxHealth > 0 then
        api.ui:set_text("adventure-health", "HEALTH  " .. tostring(math.floor(snapshot.health))
            .. " / " .. tostring(math.floor(snapshot.maxHealth)) .. "   WILDLIFE  ACTIVE")
    else
        api.ui:set_text("adventure-health", "HEALTH  -- / --   WILDLIFE  ACTIVE")
    end
end

local function discover(api, id)
    local state = trail_value()
    if state.discovered[id] == true then
        return
    end
    trail:dispatch(api, { kind = "discover", id = id })
    if id == "watchtower" then
        status = "HIGH GROUND  •  THE FOREST OPENS BELOW"
    elseif id == "relic" then
        status = "THE RELIC REMEMBERS  •  KEEP EXPLORING"
    else
        status = "DISCOVERED  " .. string.upper(id) .. "  •  FOLLOW THE NEXT CLUE"
    end
end

function Game.on_start(api)
    Game.api = api
    api.lobby:set_enabled(false)
    api.lobby:set_status("Explore the wilds, discover landmarks, and find the old watchtower.")
    api.session:start("adventure-101", { mode = "preview" })
    api.ui:set_document(player_controls())
    trail:start(api)
    update_hud(api)
end

function Game.on_interaction(api, event)
    if event.phase == "enter" then
        nearby_zone = event.id
        discover(api, event.id)
        if event.id == "watchtower" then
            status = "CLIMB THE LADDER  •  SEE THE WHOLE WILDS"
        elseif event.id == "relic" then
            status = "A HIDDEN RELIC  •  PRESS INTO THE HOLLOW"
        end
    elseif event.phase == "exit" and nearby_zone == event.id then
        nearby_zone = nil
    end
    update_hud(api)
end

function Game.on_player_event(api, event)
    survival:handle(api, event)
    if event.kind == "death" then
        status = "THE RAVINE TOOK YOU  •  TRY THE TRAIL AGAIN"
    elseif event.kind == "respawn" then
        status = "BACK AT THE TRAILHEAD  •  WATCH YOUR STEP"
    elseif event.kind == "damage" and survival.health < 35 then
        status = "HURT  •  GET BACK TO THE TRAILHEAD"
    end
    update_hud(api)
end

function Game.on_network_message(api, event)
    if trail:receive(api, event) then
        update_hud(api)
    end
end

function Game.on_tick(api, delta)
    Game.api = api
    elapsed = elapsed + delta
    trail:update(api, delta)
    update_hud(api)
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
