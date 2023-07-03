local QBCore = exports['qb-core']:GetCoreObject()
local isPlacing = false
local prevobj
local heading = 0.0
local spawnedHive = {}
local shopdude

--Functions
function RemoveSpawnedObject()
    isPlacing = false
    lib.hideTextUI()
    DeleteObject(prevobj)
    prevobj = nil
end
--
function SpawnDude()
    local model = joaat(Config.model)
    lib.requestModel(model)
    local coords = Config.Coords
    shopdude = CreatePed(0, model, coords.x, coords.y, coords.z-1.0, coords.w, false, false)

    TaskStartScenarioInPlace(shopdude, 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', 0, true)
    FreezeEntityPosition(shopdude, true)
    SetEntityInvincible(shopdude, true)
    SetBlockingOfNonTemporaryEvents(shopdude, true)
    exports.ox_target:addLocalEntity(shopdude, {
        {
            name = 'rj_bees:spawnped',
            label = 'Bee Shop',
            icon = 'fa-solid fa-shop',
            onSelect = function()
                exports.ox_inventory:openInventory('shop', { type = 'bee_shop', id = 1 })
            end
        }
    })
end

function PlaceSpawnedObject(coords, heading)
    lib.hideTextUI()
    TaskTurnPedToFaceEntity(cache.ped, prevobj, 500)
    Wait(700)
    if lib.progressCircle({
        duration = Config.PlacingDuration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer'
        },
    }) then 
        FreezeEntityPosition(prevobj, true)
        isPlacing = false

        TriggerServerEvent('rj_bees:server:spawnNewHive', coords, heading)

        DeleteObject(prevobj)

        prevobj = nil
    else
        RemoveSpawnedObject()
    end
end

function PreviewPlaceObject()
    if isPlacing then return end
    if cache.vehicle then lib.notify({description = 'You cannot use this in a vehicle!', type = 'error'}) return end
    if cache.weapon then lib.notify({description = 'You cannot use this when holding a weapon!', type = 'error'}) return end
    isPlacing = true
    local model = joaat(Config.BeehiveModel)
    lib.requestModel(model)
    LocalPlayer.state:set('invBusy', true, false)
    prevobj = CreateObject(model, GetEntityCoords(cache.ped), false, true, false)
    SetEntityAlpha(prevobj, 150, false)
    SetEntityCollision(prevobj, false, false)
    FreezeEntityPosition(prevobj, true)
    lib.showTextUI(("**%s**   \n**%s**   \n**%s**"):format('[E] - Place Hive', '[Q] - Cancel Placement', '[Scroll Wheel] - Rotate Hive'), {
        icon = 'fa-solid fa-box-archive'
    })

    while isPlacing do
        local hit, _, coords, _, material = lib.raycast.cam(1, 4)
        if exports.ox_inventory:GetItemCount('beehive') <= 0 then RemoveSpawnedObject() LocalPlayer.state:set('invBusy', false, false) break end
        if hit then
            SetEntityCoords(prevobj, coords.x, coords.y, coords.z)
            SetEntityHeading(prevobj, heading)
            PlaceObjectOnGroundProperly(prevobj)
            SetEntityDrawOutline(prevobj, true)
            local checkdistance = #(coords - GetEntityCoords(cache.ped))

            if checkdistance <= 3.0 and Config.SoilHash[material] then
                SetEntityDrawOutlineColor(0 ,255 ,0 ,1)
            else
                SetEntityDrawOutlineColor(255 ,0 ,0 ,1)
            end

            if IsControlJustPressed(0, 14) then
                heading = heading + 5
                if heading > 360 then heading = 5.0 end
            end

            if IsControlJustPressed(0, 15) then
                heading = heading - 5
                if heading < 0 then heading = 355.0 end
            end

            if IsControlJustPressed(0, 44) then
                LocalPlayer.state:set('invBusy', false, false)
                RemoveSpawnedObject()
            end

            if IsControlJustPressed(0, 38) then
                if checkdistance <= 3.0 and Config.SoilHash[material] then
                    LocalPlayer.state:set('invBusy', false, false)
                    PlaceSpawnedObject(coords, heading)
                    return
                else
                    lib.notify({
                        title = 'Placement',
                        description = 'you may not place this object here...',
                        style = {
                            backgroundColor = '#141517',
                            color = '#909296'
                        },
                        icon = 'xmark',
                        iconColor = 'red',
                    })
                    if Config.Debug then
                        print(material)
                        lib.setClipboard(material)
                        lib.notify({
                            description = 'Soil Hash copied to clipboard'
                        })
                    end
                end
            end

        end
    end
end

exports('PreviewPlaceObject', PreviewPlaceObject)

function DestroyHive(id)
    local distance = #(GetEntityCoords(cache.ped) - spawnedHive[id].coords)
    if distance > 3.0 then return end
    if lib.progressCircle({
        duration = Config.DestroyDuration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = {
            dict = 'weapons@first_person@aim_rng@generic@projectile@thermal_charge@',
            clip = 'plant_floor',
            flag = 16
        },
    }) then
        TriggerServerEvent('rj_bees:server:RemoveHive', id)
    end
end

function FeedBees(i)
    local coords = GetEntityCoords(cache.ped)
    if lib.progressCircle({
        duration = Config.FeedDuration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = {
            dict = 'weapon@w_sp_jerrycan',
            clip = 'fire',
            flag = 1,
        },
    }) then
        TriggerServerEvent('rj_bees:server:FeedBees', i)
    end
end

exports('FeedBees', FeedBees)

function GetHoneyCombs(i)
    TaskTurnPedToFaceEntity(cache.ped, spawnedHive[i].obj, 500)
    Wait(700)
    if lib.progressCircle({
        duration = Config.HoneyCombDuration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        },
        anim = {
            dict = 'missheistfbisetup1',
            clip = 'hassle_intro_loop_f'
        },
    }) then
        TriggerServerEvent('rj_bees:server:GetHoneyCombs', i)
    end
end

function OpenMenu(i)
    local coords, _, progress, queen, worker, feed = lib.callback.await('rj_bees:callback:getInfo', false, i)
    local distanceFromHive = #(GetEntityCoords(cache.ped) - vector3(coords.x, coords.y, coords.z))
    if distanceFromHive > 3.0 then return end
    local options = {}
    local harvestdescription = nil
    local harvestSelect = nil
    if progress >= 100 then
        harvestdescription = 'BATCH DONE: Press to harvest'
        harvestSelect = function()
            GetHoneyCombs(i)
        end
    end
    options[#options+1] = {
        title = 'Progress',
        icon = 'fa-solid fa-jar',
        iconColor = 'yellow',
        description = harvestdescription,
        progress = progress,
        colorScheme = 'yellow',
        metadata = {'Active Progress of making honey',{label = 'Progress', value = progress}},
        onSelect = harvestSelect
    }
    options[#options+1] = {
        title = 'Bee Feed',
        icon = 'fa-solid fa-burger',
        description = 'Press to add feed reserves for the bees',
        progress = feed,
        colorScheme = 'red',
        metadata = {'Amount of Bee Feed',{label = 'Progress', value = feed}},
        onSelect = function()
            if feed < 100 then
                local search = exports.ox_inventory:Search('count', 'beefeed')
                if search <= 0 then
                    lib.notify({
                        description = 'You do not have the feed',
                        type = 'error'
                    })
                    OpenMenu(i)
                    return
                end
                FeedBees(i)
            else
                lib.notify({
                    description = 'The feed basin is full',
                    type = 'error'
                })
                OpenMenu(i)
            end
        end
    }
    if not queen then
        local queenbee = exports.ox_inventory:Search('slots', 'queenbee')
        local disable
        local description
        if #queenbee > 0 then
            disable = false
            description = 'Add Queen Bee'
        else
            disable = true
            description = 'You do not have a queen bee!'
        end
        local queenoptions = {}
        for k, v in pairs(queenbee) do
            queenoptions[#queenoptions+1] = {
                value = v,
                label = v.label..'('..tostring(v.metadata.durability or 100)..'%)'
            }
        end
        options[#options+1] = {
            title = 'Add Queen Bee',
            icon = 'fa-brands fa-forumbee',
            description = description,
            disabled = disable,
            onSelect = function()
                local queeninfo
                if #queenbee > 1 then
                    local input = lib.inputDialog('Queen Bee Menu', {
                        {type = 'select', label = 'Select Queen Bee you would like to add', options = queenoptions, required = true, default = 'Queen Bee(?)'}
                    })
                    if not input then return end
                    queeninfo = input[1]
                else
                    queeninfo = queenbee[1]
                end
                if lib.progressCircle({
                    duration = Config.QueenBeeDuration,
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                    },
                    anim = {
                        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                        clip = 'machinic_loop_mechandplayer'
                    },
                }) then TriggerServerEvent('rj_bees:server:addQueenBee', i, queeninfo) else lib.notify({description = 'You Cancelled', type = 'error'}) end
            end
        }
    end
    local disable
    local workerbee = exports.ox_inventory:Search('count', 'bee')
    if worker > Config.MaxWorkerBees or workerbee <= 0 then
        disable = true
    else
        disable = false
    end
    if worker < Config.MaxWorkerBees then
        options[#options+1] = {
            title = 'Add worker Bee',
            description = 'Worker Bee = '..worker..'/'..tostring(Config.MaxWorkerBees),
            progress = (worker/Config.MaxWorkerBees)*100,
            icon = 'fa-brands fa-forumbee',
            disabled = disable,
            onSelect = function()
                TriggerServerEvent('rj_bees:server:addWorkerBee', {i = i})
                OpenMenu(i)
            end
        }
    end
    options[#options+1] = {
        title = 'Destroy Bee Hive',
        icon = 'fa-solid fa-burst',
        onSelect = function()
            DestroyHive(i)
        end
    }
    lib.registerContext({
        id = 'rj_bees:menu',
        title = 'Honey Progress',
        options = options
    })
    lib.showContext('rj_bees:menu')
end

function SpawnHive(i, coords, heading)
    local model
    if spawnedHive[i].progress >= 100 then
        model = joaat(Config.BeehiveModelFinish)
    else
        model = joaat(Config.BeehiveModel)
    end
    lib.requestModel(model)
    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    SetEntityHeading(obj, heading)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    exports.ox_target:addLocalEntity(obj, {
        {
            name = 'rj_bees:'..i,
            label = 'Beehive Progress',
            icon = 'fa-brands fa-forumbee',
            canInteract = function(entity, distance, coords)
                return distance <= 2.5
            end,
            onSelect = function()
                OpenMenu(i)
            end
        }
    })
    spawnedHive[i].obj = obj
end

--Events

RegisterNetEvent('rj_bees:client:SpawnHive', function(i, coords, heading)
    SpawnHive(i, coords, heading)
end)

RegisterNetEvent('rj_bees:client:UpdateTable', function(todo, id, info)
    if todo == 'add' then
        spawnedHive[id] = info
    elseif todo == 'remove' then
        if spawnedHive[id].obj then
            DeleteObject(spawnedHive[id].obj)
        end
        spawnedHive[id] = nil
    end
end)

RegisterNetEvent('rj_bees:client:setProgress', function(id, info)
    spawnedHive[id].progress = info
    if spawnedHive[id].obj ~= nil then
        DeleteObject(spawnedHive[id].obj)
        spawnedHive[id].obj = nil
    end
end)

--Thread
CreateThread(function()
    while true do
        local loc = GetEntityCoords(cache.ped)
        if spawnedHive ~= {} and loc then
            for i, v in pairs(spawnedHive) do
                if not v.obj then
                    local distance = #(loc - v.coords)
                    if distance <= 50 then
                        SpawnHive(i, v.coords, v.heading)
                        Wait(100)
                    end
                else
                    local distance = #(loc - v.coords)
                    if distance > 100 then
                        DeleteObject(v.obj)
                        v.obj = nil
                    end
                end
            end
        end
        Wait(100)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    spawnedHive = lib.callback.await('rj_bees:callback:sendTable', false)
    SpawnDude()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if QBCore.Functions.GetPlayerData() then
            Wait(5000)
            spawnedHive = lib.callback.await('rj_bees:callback:sendTable', false)
        end
        SpawnDude()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveSpawnedObject()
        for i, v in pairs(spawnedHive) do
            if v.obj then
                DeleteObject(v.obj)
            end
        end
        DeletePed(shopdude)
    end
end)

RegisterCommand('clientbeelist', function()
    print(json.encode(spawnedHive, {indent = true}))
end)
