-- ================================================
--   CLIENT MAIN
-- ================================================

local ESX, QBCore, PlayerData = nil, nil, {}
local isOnDuty   = false
local isUIOpen   = false
local currentJob = nil

-- ─── Framework Init ────────────────────────────

if Framework.Type == 'esx' then
    ESX = exports['es_extended']:getSharedObject()

elseif Framework.Type == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- ─── Helpers ───────────────────────────────────

local function GetPlayerJob()
    if Framework.Type == 'esx' then
        local ply = ESX.GetPlayerData()
        return ply.job
    elseif Framework.Type == 'qbcore' then
        local ply = QBCore.Functions.GetPlayerData()
        return ply.job
    end
    return nil
end

local function HasJob()
    local job = GetPlayerJob()
    if not job then return false end
    return job.name == Config.JobName and job.grade >= Config.MinGrade
end

local function IsBoss()
    local job = GetPlayerJob()
    if not job then return false end
    return job.name == Config.JobName and job.grade >= Config.BossGrade
end

-- ─── Notifications ─────────────────────────────

function Notify(msg, notifType, duration)
    notifType = notifType or 'info'
    duration  = duration  or 3000

    local style = Config.NotifyStyle
    if style == 'auto' then style = Framework.Type end

    if style == 'esx' then
        ESX.ShowNotification(msg)

    elseif style == 'qbcore' then
        QBCore.Functions.Notify(msg, notifType, duration)

    elseif style == 'ox_lib' then
        lib.notify({ title = Config.JobLabel, description = msg, type = notifType, duration = duration })

    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(false, true)
    end
end

-- ─── Duty Toggle ───────────────────────────────

local function SetDuty(state)
    if not HasJob() then
        Notify('You are not employed here.', 'error')
        return
    end
    TriggerServerEvent('advanced_job:setDuty', state)
end

-- ─── Register Events ───────────────────────────

RegisterNetEvent('advanced_job:dutyChanged', function(state)
    isOnDuty = state
    if state then
        Notify('You are now ^2ON DUTY^0 as ' .. Config.JobLabel, 'success')
    else
        Notify('You are now ^1OFF DUTY^0', 'error')
    end
end)

RegisterNetEvent('advanced_job:openBossMenu', function(data)
    if not IsBoss() then
        Notify('You do not have boss permissions.', 'error')
        return
    end
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openBossMenu', data = data, jobLabel = Config.JobLabel })
end)

RegisterNetEvent('advanced_job:receivePaycheck', function(amount)
    Notify('Paycheck received: $' .. amount, 'success')
end)

-- ─── NUI Callbacks ─────────────────────────────

RegisterNUICallback('closeUI', function(_, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('setPlayerGrade', function(data, cb)
    TriggerServerEvent('advanced_job:setPlayerGrade', data.citizenid, data.grade)
    cb('ok')
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    TriggerServerEvent('advanced_job:fireEmployee', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    TriggerServerEvent('advanced_job:hireEmployee', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('societyWithdraw', function(data, cb)
    TriggerServerEvent('advanced_job:societyWithdraw', data.amount)
    cb('ok')
end)

RegisterNUICallback('societyDeposit', function(data, cb)
    TriggerServerEvent('advanced_job:societyDeposit', data.amount)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('advanced_job:requestVehicle', data.model)
    cb('ok')
end)

RegisterNUICallback('toggleDuty', function(data, cb)
    SetDuty(data.state)
    cb('ok')
end)

-- ─── Vehicle Spawn ─────────────────────────────

RegisterNetEvent('advanced_job:spawnVehicle', function(model, plate)
    local loc = Config.Locations.garage.spawnCoords
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end

    local veh = CreateVehicle(model, loc.x, loc.y, loc.z, loc.w, true, false)
    SetVehicleNumberPlateText(veh, plate)
    SetEntityAsMissionEntity(veh, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    SetModelAsNoLongerNeeded(model)
    Notify('Vehicle spawned — plate: ' .. plate, 'success')
end)

-- ─── Repair System ─────────────────────────────

local isRepairing = false

local function RepairVehicle(veh)
    if isRepairing then return end
    if not HasJob() then Notify('You are not a ' .. Config.JobLabel, 'error') return end
    if Config.DutySystem and not isOnDuty then Notify('You must be on duty.', 'error') return end

    isRepairing = true
    Notify('Repairing vehicle…', 'info')

    Wait(Config.RepairSystem.repairTime)

    if Config.RepairSystem.engineRepair then
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleEngineOn(veh, true, false, true)
    end
    if Config.RepairSystem.bodyRepair then
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleDeformationFixed(veh)
        SetVehicleFixed(veh)
    end

    TriggerServerEvent('advanced_job:repairComplete', Config.RepairSystem.payPerRepair)
    Notify('Vehicle repaired! Earned $' .. Config.RepairSystem.payPerRepair, 'success')
    isRepairing = false
end

-- ─── Key Prompt / Interaction ──────────────────
--   Uses simple distance checks; swap for ox_target/qb-target if preferred

local function IsNearCoords(coords, dist)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    return #(pos - coords) <= (dist or Config.InteractDist)
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z + 0.1, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        local sleep = 1000
        local ped   = PlayerPedId()
        local pos   = GetEntityCoords(ped)

        -- Only run checks if player has the job
        if HasJob() then
            sleep = 0

            -- Boss Menu
            local bossLoc = Config.Locations.boss
            if IsNearCoords(bossLoc.coords) then
                DrawText3D(bossLoc.coords.x, bossLoc.coords.y, bossLoc.coords.z, '[E] ' .. bossLoc.label)
                if IsControlJustReleased(0, 38) then -- E key
                    if IsBoss() then
                        TriggerServerEvent('advanced_job:fetchBossData')
                    else
                        Notify('Boss access only.', 'error')
                    end
                end
            end

            -- Duty
            local dutyLoc = Config.Locations.duty
            if IsNearCoords(dutyLoc.coords) then
                DrawText3D(dutyLoc.coords.x, dutyLoc.coords.y, dutyLoc.coords.z, '[E] ' .. dutyLoc.label)
                if IsControlJustReleased(0, 38) then
                    SetDuty(not isOnDuty)
                end
            end

            -- Stash
            local stashLoc = Config.Locations.stash
            if IsNearCoords(stashLoc.coords) then
                DrawText3D(stashLoc.coords.x, stashLoc.coords.y, stashLoc.coords.z, '[E] ' .. stashLoc.label)
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('advanced_job:openStash')
                end
            end

            -- Garage
            local garageLoc = Config.Locations.garage
            if IsNearCoords(garageLoc.coords) then
                DrawText3D(garageLoc.coords.x, garageLoc.coords.y, garageLoc.coords.z, '[E] Job Garage')
                if IsControlJustReleased(0, 38) then
                    local grade = GetPlayerJob() and GetPlayerJob().grade or 0
                    local vehicles = {}
                    for g, vlist in pairs(Config.Vehicles) do
                        if grade >= g then
                            for _, v in ipairs(vlist) do
                                table.insert(vehicles, v)
                            end
                        end
                    end
                    SendNUIMessage({ action = 'openGarage', vehicles = vehicles })
                    SetNuiFocus(true, true)
                    isUIOpen = true
                end
            end

            -- Repair nearby vehicle
            if Config.RepairSystem.enabled then
                local veh = GetClosestVehicle(pos.x, pos.y, pos.z, 5.0, 0, 70)
                if DoesEntityExist(veh) and not IsVehicleSeatFree(veh, -1) == false then
                    DrawText3D(pos.x, pos.y, pos.z + 0.5, '[G] Repair Vehicle')
                    if IsControlJustReleased(0, 47) then -- G key
                        RepairVehicle(veh)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ─── Framework Job Update Events ───────────────

if Framework.Type == 'esx' then
    AddEventHandler('esx:setJob', function(job)
        currentJob = job
    end)
elseif Framework.Type == 'qbcore' then
    AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
        currentJob = job
    end)
end

-- ─── On Resource Start ─────────────────────────

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Ask server if player is on duty (persists across reconnects)
    TriggerServerEvent('advanced_job:syncDuty')
end)

RegisterNetEvent('advanced_job:syncDutyState', function(state)
    isOnDuty = state
end)
