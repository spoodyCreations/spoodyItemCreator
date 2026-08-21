local resource = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resource, 'version', 0) or '0.0.0'
local successorName = 'bd_oxeditor'
local successorRepo = 'Binary-Development/bd_oxeditor'
local successorUrl = 'https://github.com/Binary-Development/bd_oxeditor'
local latestVersion
local behind = false

Deprecation = {}

---@param version string
---@return number[]
local function parseVersion(version)
    local parts = {}

    for chunk in version:gmatch('%d+') do
        parts[#parts + 1] = tonumber(chunk)
    end

    return parts
end

---@param installed string
---@param latest string
---@return boolean
local function isBehind(installed, latest)
    local left, right = parseVersion(installed), parseVersion(latest)
    local count = math.max(#left, #right)

    for i = 1, count do
        local mine, theirs = left[i] or 0, right[i] or 0

        if mine ~= theirs then return mine < theirs end
    end

    return false
end

local function printNotice()
    print(('^1[%s] %s is out of date and no longer receives updates.^0'):format(resource, resource))
    print(('^3Development has moved to %s — every new feature and fix ships there instead.^0'):format(successorName))

    if latestVersion then
        print(('^3Installed: %s  |  Latest %s release: %s%s^0'):format(currentVersion, successorName, latestVersion, behind and '  (newer)' or ''))
    end

    print(('^5%s^0'):format(successorUrl))
end

---@param source? number
function Deprecation.notify(source)
    if not source or source <= 0 then
        return printNotice()
    end

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'warning',
        position = 'top',
        title = 'Item Creator is discontinued',
        description = ('%s %s is out of date and no longer maintained. Development has moved to %s%s — github.com/%s'):format(
            resource,
            currentVersion,
            successorName,
            latestVersion and (' ' .. latestVersion) or '',
            successorRepo
        ),
        duration = 15000,
    })
end

local function checkVersion()
    PerformHttpRequest(('https://api.github.com/repos/%s/releases/latest'):format(successorRepo), function(status, body)
        if status == 200 and body then
            local ok, data = pcall(json.decode, body)
            local tag = ok and type(data) == 'table' and data.tag_name

            if type(tag) == 'string' and tag ~= '' then
                latestVersion = tag
                behind = isBehind(currentVersion, tag)
            end
        end

        printNotice()
    end, 'GET', '', {
        ['User-Agent'] = resource,
        ['Accept'] = 'application/vnd.github+json',
    })
end

CreateThread(function()
    Wait(2000)
    checkVersion()
end)
