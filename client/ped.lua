-- ================================================
--   CLIENT PED SPAWNER
-- ================================================

local spawnedPeds = {}

local function SpawnPed(data, coords)
    local model = GetHashKey(data.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityHeading(ped, coords.w)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdoll(ped, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    if data.scenario then
        TaskStartScenarioInPlace(ped, data.scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(model)
    table.insert(spawnedPeds, ped)
end

CreateThread(function()
    Wait(1000) -- small delay for world to load

    if Config.Locations.boss.ped then
        SpawnPed(Config.Locations.boss.ped, Config.Locations.boss.coords)
    end
    if Config.Locations.duty.ped then
        SpawnPed(Config.Locations.duty.ped, Config.Locations.duty.coords)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
