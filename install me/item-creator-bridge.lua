if _itemCreatorBridge then return end
_itemCreatorBridge = true

local host = GetCurrentResourceName()
local itemsFile = 'data/items.lua'
local imagesDir = 'web/images/'
local backupFile = 'data/items.itemcreator.bak'
local imageManifest = 'data/items.itemcreator.images.json'
local beginTag = '-- item-creator items (auto-generated, do not edit)'
local endTag = '-- item-creator end'
local delBeginTag = '-- item-creator deletions (auto-generated, do not edit)'
local delEndTag = '-- item-creator deletions end'

---@class ItemDef
---@field name string
---@field label string
---@field weight number
---@field stack boolean
---@field close boolean
---@field description string
---@field consumable boolean
---@field export string
---@field imageUrl string

local downloaded = {}

---@param item ItemDef
---@return string?
local function itemExport(item)
    if type(item.export) == 'string' and item.export ~= '' then return item.export end
    return nil
end

---@param value any
---@return string
local function quote(value)
    local s = tostring(value)
        :gsub('\\', '\\\\')
        :gsub("'", "\\'")
        :gsub('\n', '\\n')
        :gsub('\r', '\\r')
        :gsub('\0', '\\0')
    return "'" .. s .. "'"
end

---@param item ItemDef
---@return string
local function serialize(item)
    local export = itemExport(item)

    local lines = {
        ('\t[%s] = {'):format(quote(item.name)),
        ('\t\tlabel = %s,'):format(quote(item.label or item.name)),
        ('\t\tweight = %d,'):format(tonumber(item.weight) or 0),
        ('\t\tstack = %s,'):format(tostring(item.stack ~= false)),
        ('\t\tclose = %s,'):format(tostring(item.close ~= false)),
    }

    if item.description and item.description ~= '' then
        lines[#lines + 1] = ('\t\tdescription = %s,'):format(quote(item.description))
    end

    if item.consumable then
        lines[#lines + 1] = '\t\tconsume = 1,'
    elseif export then
        lines[#lines + 1] = '\t\tconsume = 0,'
    end

    if export then
        lines[#lines + 1] = ('\t\tclient = { export = %s },'):format(quote(export))
    end

    lines[#lines + 1] = '\t},'

    return table.concat(lines, '\n')
end

---@param items ItemDef[]
---@return string
local function buildItemsRegion(items)
    local out = { '\t' .. beginTag }

    for i = 1, #items do
        out[#out + 1] = serialize(items[i])
    end

    out[#out + 1] = '\t' .. endTag

    return table.concat(out, '\n')
end

---@param deletions string[]
---@return string
local function buildDeletionsRegion(deletions)
    local out = { delBeginTag, 'do' }

    for i = 1, #deletions do
        out[#out + 1] = ('\titems[%s] = nil'):format(quote(deletions[i]))
    end

    out[#out + 1] = 'end'
    out[#out + 1] = delEndTag

    return table.concat(out, '\n')
end

---@param content string
---@return string?
local function normalize(content)
    if content:find('return%s+items') then return content end
    if not content:find('return%s*{') then return end

    content = content:gsub('return%s*{', 'local items = {', 1)

    return content:gsub('%s+$', '') .. '\n\nreturn items\n'
end

---@param content string
---@return string
local function stripItemsRegion(content)
    local s = content:find(beginTag, 1, true)
    if not s then return content end

    local e = content:find(endTag, s, true)
    if not e then return content end

    local cut = e + #endTag
    local start = s

    while start > 1 and content:sub(start - 1, start - 1):match('[ \t]') do
        start = start - 1
    end
    if content:sub(start - 1, start - 1) == '\n' then start = start - 1 end

    return content:sub(1, start - 1) .. content:sub(cut)
end

---@param content string
---@return string
local function stripDeletionsRegion(content)
    local s = content:find(delBeginTag, 1, true)
    if not s then return content end

    local e = content:find(delEndTag, s, true)
    if not e then return content end

    local cut = e + #delEndTag
    local n = 0

    while n < 2 and content:sub(cut, cut) == '\n' do
        cut = cut + 1
        n = n + 1
    end

    return content:sub(1, s - 1) .. content:sub(cut)
end

---@param content string
---@return string
local function collapseBlanks(content)
    return (content:gsub('\n\n\n+', '\n\n'))
end

---@param content string
---@param region string
---@return string?
local function injectItemsRegion(content, region)
    local _, e = content:find('local%s+items%s*=%s*{')
    if not e then
        _, e = content:find('return%s*{')
    end
    if not e then return end

    return content:sub(1, e) .. '\n' .. region .. content:sub(e + 1)
end

---@param content string
---@param region string
---@return string?
local function injectDeletionsRegion(content, region)
    local pos, from = nil, 1

    while true do
        local a = content:find('return%s+items', from)
        if not a then break end
        pos, from = a, a + 1
    end

    if not pos then return end

    local lineStart = pos
    while lineStart > 1 and content:sub(lineStart - 1, lineStart - 1) ~= '\n' do
        lineStart = lineStart - 1
    end

    return content:sub(1, lineStart - 1) .. region .. '\n\n' .. content:sub(lineStart)
end

---@param items ItemDef[]
---@param deletions string[]
---@return boolean ok, string? err
local function writeItems(items, deletions)
    local original = LoadResourceFile(host, itemsFile)
    if not original or original == '' then
        return false, 'could not read items.lua'
    end

    local content = normalize(original)
    if not content then
        return false, 'items.lua is in an unexpected format'
    end

    content = stripItemsRegion(content)
    content = stripDeletionsRegion(content)
    content = collapseBlanks(content)

    local final = injectItemsRegion(content, buildItemsRegion(items))
    if not final then
        return false, 'could not find the items table'
    end

    if #deletions > 0 then
        final = injectDeletionsRegion(final, buildDeletionsRegion(deletions))
        if not final then
            return false, 'could not find `return items`'
        end
    end

    if not load(final) then
        return false, 'generated items.lua would not compile'
    end

    SaveResourceFile(host, backupFile, original, #original)
    SaveResourceFile(host, itemsFile, final, #final)

    return true
end

---@param items ItemDef[]
local function downloadImages(items)
    for i = 1, #items do
        local item = items[i]
        local url = item.imageUrl

        if url and url:match('^https?://') and not downloaded[item.name] then
            PerformHttpRequest(url, function(status, body)
                if status == 200 and body and #body > 0 then
                    SaveResourceFile(host, imagesDir .. item.name .. '.png', body, #body)
                    downloaded[item.name] = true
                else
                    lib.print.warn(('item-creator image download failed for "%s" (HTTP %s)'):format(item.name, status))
                end
            end, 'GET', '', { ['User-Agent'] = 'item-creator' })
        end
    end
end

---@return table<string, boolean>
local function loadImageManifest()
    local set = {}
    local raw = LoadResourceFile(host, imageManifest)

    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            for i = 1, #decoded do
                if type(decoded[i]) == 'string' then set[decoded[i]] = true end
            end
        end
    end

    return set
end

---@param set table<string, boolean>
local function saveImageManifest(set)
    local arr = {}
    for name in pairs(set) do arr[#arr + 1] = name end
    table.sort(arr)
    SaveResourceFile(host, imageManifest, json.encode(arr), -1)
end

---@param name string
local function removeImageFile(name)
    if type(name) ~= 'string' or not name:match('^[%l%d_]+$') then return end

    local base = GetResourcePath(host)
    if not base or base == '' then return end

    os.remove((base:gsub('\\', '/') .. '/' .. imagesDir .. name .. '.png'))
end

---@param items ItemDef[]
local function syncImages(items)
    local managed = loadImageManifest()
    local current = {}

    for i = 1, #items do
        local item = items[i]
        if item.imageUrl and item.imageUrl ~= '' then
            current[item.name] = true
        end
    end

    for name in pairs(managed) do
        if not current[name] then
            removeImageFile(name)
            downloaded[name] = nil
        end
    end

    saveImageManifest(current)
end

local serverItemList

---@return table<string, table>?
local function getItemList()
    if serverItemList then return serverItemList end

    local ok, list = pcall(require, 'modules.items.shared')
    if ok and type(list) == 'table' then serverItemList = list end

    return serverItemList
end

---@param item ItemDef
---@return table
local function baseDef(item)
    return {
        name = item.name,
        label = item.label or item.name,
        weight = tonumber(item.weight) or 0,
        stack = item.stack ~= false,
        close = item.close ~= false,
        description = item.description or '',
        consume = item.consumable and 1 or 0,
    }
end

---@param items ItemDef[]
---@param deletions string[]
local function registerLive(items, deletions)
    local list = getItemList()
    if type(list) ~= 'table' then return end

    for i = 1, #items do
        list[items[i].name] = baseDef(items[i])
    end

    for i = 1, #deletions do
        list[deletions[i]] = nil
    end
end

---@param items ItemDef[]
---@return table[]
local function buildClientPayload(items)
    local out = {}

    for i = 1, #items do
        local item = items[i]
        local def = baseDef(item)
        def.export = itemExport(item)

        if type(item.imageUrl) == 'string' and item.imageUrl:match('^https?://') then
            def.image = item.imageUrl
        end

        out[#out + 1] = def
    end

    return out
end

---@param items ItemDef[]
---@param deletions string[]
local function refreshClients(items, deletions)
    registerLive(items, deletions)
    TriggerClientEvent('item-creator:refreshClientItems', -1, buildClientPayload(items), deletions)
end

AddEventHandler('item-creator:apply', function(items, deletions, source)
    if type(items) ~= 'table' or type(deletions) ~= 'table' then return end

    refreshClients(items, deletions)
    syncImages(items)
    downloadImages(items)

    local ok, err = writeItems(items, deletions)
    if not ok then
        lib.print.error('item-creator bridge: ' .. err)
    end

    if source then
        TriggerClientEvent('ox_lib:notify', source, {
            type = ok and 'success' or 'error',
            position = 'top',
            title = 'Item Creator',
            description = ok and 'Items applied. Connected players got them live; new items appear as soon as they\'re received.'
                or ('Failed to write items.lua: ' .. err),
        })
    end
end)

---@return CustomItem[] customItems, string[] deletedItems
local function readStore()
    local raw = LoadResourceFile('item-creator', 'data/config.json')
    if not raw or raw == '' then return {}, {} end

    local ok, cfg = pcall(json.decode, raw)
    if not ok or type(cfg) ~= 'table' then return {}, {} end

    return cfg.customItems or {}, cfg.deletedItems or {}
end

exports('refreshItems', function(rewrite)
    local items, deletions = readStore()

    refreshClients(items, deletions)

    if rewrite ~= false then
        local ok, err = writeItems(items, deletions)
        if not ok then lib.print.error('item-creator bridge refreshItems: ' .. err) end
    end

    return true
end)
