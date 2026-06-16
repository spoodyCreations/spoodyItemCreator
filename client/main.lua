local rpcPrefix = 'item-creator:'

RegisterNetEvent('item-creator:open', function(data)
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open', config = data })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('rpc', function(data, cb)
    if type(data) ~= 'table' or type(data.event) ~= 'string' or data.event:sub(1, #rpcPrefix) ~= rpcPrefix then
        return cb(nil)
    end

    cb(lib.callback.await(data.event, false, table.unpack(data.args or {})))
end)

local function suggestCommand()
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Open the Item Creator admin panel')
end

AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() or resource == 'chat' then
        suggestCommand()
    end
end)
