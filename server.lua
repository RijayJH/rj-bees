local QBCore = exports['qb-core']:GetCoreObject()
local spawnedHives = {}

RegisterNetEvent('rj_bees:server:spawnNewHive', function(coords, heading)
    local src = source
    local ped = GetPlayerPed(src)

    local distanceFromHive = #(GetEntityCoords(ped) - coords)

    if distanceFromHive > 3.0 then return end
    local i = #spawnedHives+1
    spawnedHives[i] = {coords = coords, heading = heading, progress = 0, queen = false, worker = 0, feed = 0, queenhealth = 0}
    TriggerClientEvent('rj_bees:client:UpdateTable', -1, 'add', i, spawnedHives[i])
    --TriggerClientEvent('rj_bees:client:SpawnHive', src, i, coords, heading)
    exports.ox_inventory:RemoveItem(src, 'beehive', 1)
end)

RegisterNetEvent('rj_bees:server:RemoveHive', function(id)
    local src = source
    TriggerClientEvent('rj_bees:client:UpdateTable', -1, 'remove', id)
    if spawnedHives[id].queen then
        exports.ox_inventory:AddItem(src, 'queenbee', 1, {durability = spawnedHives[id].queenhealth})
    end
    spawnedHives[id] = nil
end)

lib.callback.register('rj_bees:callback:getInfo', function(source, i)
    if not spawnedHives[i] then return false end
    local info = spawnedHives[i]
    return info.coords, info.heading, info.progress, info.queen, info.worker, info.feed
end)

lib.callback.register('rj_bees:callback:sendTable', function()
    return spawnedHives
end)

RegisterNetEvent('rj_bees:server:addQueenBee', function(i, info)
    local src = source
    local ped = GetPlayerPed(src)

    local distanceFromHive = #(GetEntityCoords(ped) - spawnedHives[i].coords)

    if distanceFromHive > 3.0 then return end
    exports.ox_inventory:RemoveItem(src, info.name, 1, info.metadata, info.slot)
    spawnedHives[i].queen = true
    if info.metadata.durability then
        spawnedHives[i].queenhealth = info.metadata.durability
    else
        spawnedHives[i].queenhealth = 100
    end
    TriggerClientEvent('ox_lib:notify', src, {description = 'Queen Bee Added', type = 'success'})
end)

RegisterNetEvent('rj_bees:server:FeedBees', function(i)
    if not spawnedHives[i] then return end
    local src = source
    local ped = GetPlayerPed(src)

    local distanceFromHive = #(GetEntityCoords(ped) - spawnedHives[i].coords)

    if distanceFromHive > 3.0 then return end
    local search = exports.ox_inventory:Search(src, 'slots', 'beefeed')
    if #search > 1 then
        table.sort(search, function (k1, k2) return k1.metadata.durability < k2.metadata.durability end )
    end
    if #search > 0 then
        local newdura = search[1].metadata.durability - 20
        if newdura < 0 then newdura = 0 end
        exports.ox_inventory:SetDurability(src, search[1].slot, newdura)
        local newinfo = exports.ox_inventory:GetSlot(src, search[1].slot)
        if newinfo.metadata.durability <= 0 then
            exports.ox_inventory:RemoveItem(src, 'beefeed', 1, {durability = 0}, newinfo.slot)
        end
        spawnedHives[i].feed = spawnedHives[i].feed + 40
        if spawnedHives[i].feed > 100 then spawnedHives[i].feed = 100 end
    end
end)

RegisterNetEvent('rj_bees:server:GetHoneyCombs', function(i)
    if not spawnedHives[i] then return end
    local src = source
    local ped = GetPlayerPed(src)

    local distanceFromHive = #(GetEntityCoords(ped) - spawnedHives[i].coords)

    if distanceFromHive > 3.0 then return end
    math.randomseed(os.time())
    local amount = math.random(Config.HoneyCombAmount)
    exports.ox_inventory:AddItem(src, 'honeycombs', amount, {durability = 100})
    spawnedHives[i].progress = 0
    spawnedHives[i].queenhealth = spawnedHives[i].queenhealth - math.random(Config.QueenHealthAfterHarvest)
    TriggerClientEvent('rj_bees:client:setProgress', -1, i, 0)
end)

RegisterNetEvent('rj_bees:server:addWorkerBee', function(data)
    local src = source
    local ped = GetPlayerPed(src)

    local distanceFromHive = #(GetEntityCoords(ped) - spawnedHives[data.i].coords)

    if distanceFromHive > 3.0 then return end
    exports.ox_inventory:RemoveItem(src, 'bee', 1)
    spawnedHives[data.i].worker = spawnedHives[data.i].worker + 1
    TriggerClientEvent('ox_lib:notify', src, {description = 'Worker Bee Added', type = 'success'})
end)

function StoreHivesTable()
    SaveResourceFile(GetCurrentResourceName(), "hives.json", json.encode(spawnedHives), -1)
end

RegisterNetEvent('rj_bees:server:AddTimeMeta', function(x, wht)
    CreateThread(function()
        local time = os.time()
        Wait(100)
        if wht == 'add' then
            x.fromSlot.metadata.time = time
            if not x.fromSlot.metadata.remtime then
                x.fromSlot.metadata.remtime = Config.HoursTakenToDegrade
            end
        else
            x.fromSlot.metadata.time = nil
        end
        exports.ox_inventory:SetMetadata(x.toInventory, x.toSlot, x.fromSlot.metadata)
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        spawnedHives = json.decode(LoadResourceFile(GetCurrentResourceName(), 'hives.json'))
        for i, v in pairs(spawnedHives) do
            local coords = v.coords
            spawnedHives[i].coords = vector3(v.coords.x, v.coords.y, v.coords.z)
        end
        exports.ox_inventory:RegisterShop('bee_shop', {
            name = 'Bee Hives',
            inventory = {
                { name = 'beehive', price = 800, count = 20 },
                { name = 'beefeed', price = 50, metadata = {durability = 100}}
            },
            locations = {
                vec3(-695.56, 5802.11, 17.33),
            },
        })
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        StoreHivesTable()
    end
end)

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

exports.ox_inventory:registerHook('swapItems', function(payload)
    if payload.fromType == 'player' and payload.toType == 'stash' and payload.action == 'move' then
        TriggerEvent('rj_bees:server:AddTimeMeta', payload, 'add')
    elseif payload.fromType == 'stash' and payload.toType == 'player' and payload.action == 'move' then
        TriggerEvent('rj_bees:server:AddTimeMeta', payload, 'remove')
    end
    return true
end, {
    print = false,
    itemFilter = {
        honeycombs = true,
    },
})

local function setData(inventory, slot, data)
    SetTimeout(0, function()
        exports.ox_inventory:SetMetadata(inventory, slot, data)
    end)
end



local function changeItem(inv, item1, item2)
    CreateThread(function()
        exports.ox_inventory:RemoveItem(inv, item1.name, 1, nil, item1.slot)
        Wait(100)
        exports.ox_inventory:AddItem(inv, item2, 1, nil, item1.slot)
    end)
end

-- function Translate(info)
--     CreateThread(function()
--         local time = os.time()
--         local search = exports.ox_inventory:Search(info.inventoryId, 'slots', 'honeycombs')
--         if #search > 0 then
--             for i, v in pairs(search) do
--                 local difftime = time - v.metadata.time
--                 local percent = ((v.metadata.remtime - difftime)/Config.HoursTakenToDegrade)*100
--                 v.metadata.durability = math.ceil(percent)
--                 if v.metadata.durability < 0 then v.metadata.durability = 0 end
--                 v.metadata.time = time
--                 v.metadata.remtime = v.metadata.remtime - difftime
--                 if v.metadata.durability <= 0 then
--                     changeItem(info.inventoryId, v, 'honey')
--                 else
--                     setData(info.inventoryId, v.slot, v.metadata)
--                 end
--             end
--         end
--     end)
-- end

exports.ox_inventory:registerHook('openInventory', function(info)
    if info.inventoryType == "stash" then
        local search = exports.ox_inventory:Search(info.inventoryId, 'slots', 'honeycombs')
        if #search > 0 then
            local time = os.time()
            for i, v in pairs(search) do
                local difftime = time - v.metadata.time
                local percent = ((v.metadata.remtime - difftime)/Config.HoursTakenToDegrade)*100
                v.metadata.durability = math.ceil(percent)
                if v.metadata.durability < 0 then v.metadata.durability = 0 end
                v.metadata.time = time
                v.metadata.remtime = v.metadata.remtime - difftime
                if v.metadata.durability <= 0 then
                    changeItem(info.inventoryId, v, 'honey')
                else
                    setData(info.inventoryId, v.slot, v.metadata)
                end
            end
        end
    end
end, {
    print = false,
})

--Intervals
local hourslash = ''
local minslash = ''

if Config.Hours ~= '' then
    hourslash = '/'
end

if Config.Mins ~= '' then
    minslash = '/'
end

lib.cron.new('*'..minslash..Config.Mins..' *'..hourslash..Config.Hours..' * * *', function(task, date)
    for i, v in pairs(spawnedHives) do
        if v.queen and v.worker > 0 then
            local amount = math.floor((v.worker/Config.MaxWorkerBees) * Config.WorkforceMultiplier)
            if v.feed <= 0 then
                amount = math.floor(amount * Config.NoFoodMultiplier)
            end
            if v.progress ~= 100 then
                v.progress = v.progress + amount
                if v.progress > 100 then v.progress = 100 end
                if v.progress == 100 then TriggerClientEvent('rj_bees:client:setProgress', -1, i, 100) end
            end
            if v.feed <= 0 then
                math.randomseed(os.time())
                local rand = math.random(100)
                if rand <= Config.WorkerBeeKillPercent then
                    v.worker = v.worker - Config.KillWorker
                    v.queenhealth = v.queenhealth - Config.ReduceQueenHealth
                    if v.queenhealth <= 0 then
                        v.queen = false
                        v.queenhealth = 0
                    end
                end
            end
            if v.progress ~= 100 then
                v.feed = v.feed - math.ceil((v.worker/Config.MaxWorkerBees) * Config.FoodMultiplier)
            end
            if v.feed < 0 then v.feed = 0 end

        end
    end
end, {
    debug = false
})

-- RegisterCommand('givebeecombs', function(source, args, rawCommand)
--     exports.ox_inventory:AddItem(source, 'honeycombs', 1, {durability = 100})
-- end)