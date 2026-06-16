---@diagnostic disable: lowercase-global
if not lib then return end
if _itemCreatorBridgeClient then return end

_itemCreatorBridgeClient = true

---@param spec string
---@return (fun(...): any)?
local function wireExport(spec)
    local resource, name = spec:match('^([^.]+)%.(.+)$')

    if not resource or not name then
        return
    end

    return function(...)
        return exports[resource][name](nil, ...)
    end
end

---@return table<string, table>?
local function getItemList()
    local ok, list = pcall(require, 'modules.items.shared')

    if ok and type(list) == 'table' then
        return list
    end
end

---@param items table[]
local function rewarmNui(items)
    if not client or not client.uiLoaded then return end
    if type(PlayerData) ~= 'table' or type(PlayerData.inventory) ~= 'table' then return end

    local itemData = {}

    for i = 1, #items do
        local item = items[i]
        if type(item) == 'table' and type(item.name) == 'string' then
            itemData[item.name] = {
                label = item.label or item.name,
                stack = item.stack ~= false,
                close = item.close ~= false,
                count = 0,
                description = item.description or '',
                image = (type(item.image) == 'string' and item.image ~= '') and item.image or nil,
            }
        end
    end

    if not next(itemData) then return end

    SendNUIMessage({
        action = 'init',
        data = {
            items = itemData,
            leftInventory = {
                id = cache.playerId,
                slots = shared.playerslots,
                items = PlayerData.inventory,
                maxWeight = shared.playerweight,
            },
            imagepath = client.imagepath,
        },
    })
end

RegisterNetEvent('item-creator:refreshClientItems', function(items, deletions)
    if type(items) ~= 'table' then return end

    local list = getItemList()
    if type(list) ~= 'table' then return end

    for i = 1, #items do
        local item = items[i]

        if type(item) == 'table' and type(item.name) == 'string' then
            local def = {
                name = item.name,
                label = item.label or item.name,
                weight = tonumber(item.weight) or 0,
                stack = item.stack ~= false,
                close = item.close ~= false,
                description = item.description or '',
                consume = tonumber(item.consume) or 0,
                count = 0,
            }

            if type(item.image) == 'string' and item.image ~= '' then
                def.image = item.image
            end

            if type(item.export) == 'string' and item.export ~= '' then
                def.client = { export = item.export }
                def.export = wireExport(item.export)
            end

            list[item.name] = def
        end
    end

    if type(deletions) == 'table' then
        for i = 1, #deletions do
            if type(deletions[i]) == 'string' then list[deletions[i]] = nil end
        end
    end

    pcall(rewarmNui, items)
end)
