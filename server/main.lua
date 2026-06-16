local resource = GetCurrentResourceName()
local storeFile = 'data/config.json'
local ox = exports.ox_inventory
local namePattern = '^[%l%d_]+$'
local exportPattern = '^[%w_%-]+%.[%w_]+$'
local commandAce = 'command.' .. Config.Command

---@class CustomItem
---@field id string
---@field name string
---@field label string
---@field weight number
---@field stack boolean
---@field close boolean
---@field description string
---@field imageUrl string
---@field consumable boolean
---@field export string

---@class Store
---@field customItems CustomItem[]
---@field deletedItems string[]
local store = { customItems = {}, deletedItems = {} }

local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, commandAce) or IsPlayerAceAllowed(source, Config.Ace)
end

---@param raw any
---@return CustomItem?
local function sanitizeItem(raw)
    if type(raw) ~= 'table' or type(raw.name) ~= 'string' then return end

    local name = raw.name:lower()
    if not name:match(namePattern) then return end

    local export = type(raw.export) == 'string' and raw.export or ''

    if export ~= '' and not export:match(exportPattern) then
        export = ''
    end

    return {
        id = type(raw.id) == 'string' and raw.id or name,
        name = name,
        label = (type(raw.label) == 'string' and raw.label ~= '') and raw.label or name,
        weight = math.max(0, math.floor(tonumber(raw.weight) or 0)),
        stack = raw.stack ~= false,
        close = raw.close ~= false,
        description = type(raw.description) == 'string' and raw.description or '',
        imageUrl = type(raw.imageUrl) == 'string' and raw.imageUrl or '',
        consumable = raw.consumable == true,
        export = export,
    }
end

---@param list any
---@return CustomItem[]
local function sanitizeItems(list)
    local out = {}

    if type(list) == 'table' then
        for i = 1, #list do
            local item = sanitizeItem(list[i])
            if item then out[#out + 1] = item end
        end
    end

    return out
end

---@param list any
---@return string[]
local function sanitizeNames(list)
    local out, seen = {}, {}

    if type(list) == 'table' then
        for i = 1, #list do
            local name = list[i]

            if type(name) == 'string' and name:match(namePattern) and not seen[name] then
                seen[name] = true
                out[#out + 1] = name
            end
        end
    end

    return out
end

local function persist()
    SaveResourceFile(resource, storeFile, json.encode(store, { indent = true }), -1)
end

local function loadStore()
    local raw = LoadResourceFile(resource, storeFile)
    local decoded = raw and raw ~= '' and json.decode(raw)

    if type(decoded) ~= 'table' then
        return persist()
    end

    store.customItems = sanitizeItems(decoded.customItems)
    store.deletedItems = sanitizeNames(decoded.deletedItems)
end

---@param source? number
local function apply(source)
    TriggerEvent('item-creator:apply', store.customItems, store.deletedItems, source)
end

lib.callback.register('item-creator:getOxItems', function(source)
    if not isAdmin(source) then return {} end

    local list = ox:Items()

    if type(list) ~= 'table' then
        return {}
    end

    local out = {}

    for name, def in pairs(list) do
        local image = def.client and def.client.image

        out[#out + 1] = {
            name = name,
            label = def.label or name,
            weight = tonumber(def.weight) or 0,
            stack = def.stack ~= false,
            close = def.close ~= false,
            description = type(def.description) == 'string' and def.description or '',
            consumable = (tonumber(def.consume) or 0) > 0,
            image = (type(image) == 'string' and image ~= '') and image or nil,
        }
    end

    table.sort(out, function(a, b)
        return a.label:lower() < b.label:lower()
    end)

    return out
end)

lib.callback.register('item-creator:saveConfig', function(source, cfg)
    if not isAdmin(source) or type(cfg) ~= 'table' then return false end

    store.customItems = sanitizeItems(cfg.customItems)
    store.deletedItems = sanitizeNames(cfg.deletedItems)

    persist()
    apply()

    return true
end)

lib.callback.register('item-creator:reapplyItems', function(source)
    if not isAdmin(source) then return false end

    apply(source)

    return true
end)

---@param source? number
---@return boolean
local function refreshLive(source)
    local ok, result = pcall(function()
        return ox:refreshItems(false)
    end)

    local success = ok and result ~= false

    if source and source > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            type = success and 'success' or 'error',
            position = 'top',
            title = 'Item Creator',
            description = success and 'Re-pushed items to online players.' or 'Refresh failed — is the ox_inventory bridge installed?',
        })
    end

    return success
end

lib.callback.register('item-creator:refreshLive', function(source)
    if not isAdmin(source) then return false end

    return refreshLive(source)
end)

---@param source? number
local function installBridge(source)
    local oxName = 'ox_inventory'
    local serverLine = "server_scripts { 'item-creator-bridge.lua' }"
    local clientLine = "client_scripts { 'item-creator-bridge.client.lua' }"

    ---@param ntype 'success' | 'error' | 'inform'
    ---@param msg string
    ---@param extra? string
    local function report(ntype, msg, extra)
        local color = ntype == 'success' and '^2' or ntype == 'error' and '^1' or '^3'
        print(('%s[item-creator] %s^0'):format(color, msg))
        if extra then print(extra) end

        if source and source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                type = ntype,
                position = 'top',
                title = 'Item Creator',
                description = msg,
                duration = 12000,
            })
        end
    end

    if GetResourceState(oxName) == 'missing' then
        return report('error', 'ox_inventory was not found on this server.')
    end

    local manifest = LoadResourceFile(oxName, 'fxmanifest.lua')

    if manifest
        and manifest:find('item-creator-bridge.lua', 1, true)
        and manifest:find('item-creator-bridge.client.lua', 1, true) then
        return report('success', ('ox_inventory is already wired. Run `restart %s` to apply changes.'):format(oxName))
    end

    report('inform', ("Copy bridge/item-creator-bridge.lua and bridge/item-creator-bridge.client.lua into the %s folder, add these two lines to its fxmanifest.lua, then `restart %s`:"):format(oxName, oxName), ('^3%s\n%s^0'):format(serverLine, clientLine))
end

lib.addCommand(Config.Command, {
    help = 'Open the Item Creator panel; "refresh" re-pushes items live, "install" shows the ox_inventory bridge lines',
    params = {
        { name = 'action', help = 'empty = open; refresh = re-push live; install = show the ox_inventory bridge lines', type = 'string', optional = true },
    },
    restricted = Config.Ace,
}, function(source, args)
    if args.action == 'refresh' then
        return refreshLive(source)
    elseif args.action == 'install' then
        return installBridge(source)
    end

    TriggerClientEvent('item-creator:open', source, store)
end)

CreateThread(function()
    loadStore()

    lib.waitFor(function()
        if GetResourceState('ox_inventory') == 'started' then return true end
    end, 'ox_inventory did not start', 30000)

    apply()
end)
