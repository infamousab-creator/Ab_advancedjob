-- ================================================
--   SERVER FRAMEWORK BRIDGE
-- ================================================

local ESX, QBCore = nil, nil

if Framework.Type == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif Framework.Type == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- ─── Get Player Object ─────────────────────────

function GetPlayer(source)
    if Framework.Type == 'esx' then
        return ESX.GetPlayerFromId(source)
    elseif Framework.Type == 'qbcore' then
        return QBCore.Functions.GetPlayer(source)
    end
end

-- ─── Get Player Identifier ─────────────────────

function GetIdentifier(source)
    if Framework.Type == 'esx' then
        local ply = GetPlayer(source)
        return ply and ply.identifier or nil
    elseif Framework.Type == 'qbcore' then
        local ply = GetPlayer(source)
        return ply and ply.PlayerData.citizenid or nil
    end
end

-- ─── Get Player Job ────────────────────────────

function GetJob(source)
    if Framework.Type == 'esx' then
        local ply = GetPlayer(source)
        if not ply then return nil end
        return { name = ply.job.name, grade = ply.job.grade_index or ply.job.grade }
    elseif Framework.Type == 'qbcore' then
        local ply = GetPlayer(source)
        if not ply then return nil end
        return { name = ply.PlayerData.job.name, grade = ply.PlayerData.job.grade.level }
    end
end

-- ─── Has Job Check ─────────────────────────────

function HasJob(source, minGrade)
    local job = GetJob(source)
    if not job then return false end
    return job.name == Config.JobName and job.grade >= (minGrade or Config.MinGrade)
end

function IsBoss(source)
    return HasJob(source, Config.BossGrade)
end

-- ─── Add Money ─────────────────────────────────

function AddMoney(source, amount, reason)
    if Framework.Type == 'esx' then
        local ply = GetPlayer(source)
        if ply then ply.addMoney(amount) end
    elseif Framework.Type == 'qbcore' then
        local ply = GetPlayer(source)
        if ply then ply.Functions.AddMoney('cash', amount, reason or 'job-payment') end
    end
end

-- ─── Set Job ───────────────────────────────────

function SetJob(source, jobName, grade)
    if Framework.Type == 'esx' then
        local ply = GetPlayer(source)
        if ply then ply.setJob(jobName, grade) end
    elseif Framework.Type == 'qbcore' then
        local ply = GetPlayer(source)
        if ply then ply.Functions.SetJob(jobName, grade) end
    end
end

-- ─── Get All Players ───────────────────────────

function GetAllPlayers()
    if Framework.Type == 'esx' then
        return ESX.GetPlayers()
    elseif Framework.Type == 'qbcore' then
        local players = {}
        for _, ply in pairs(QBCore.Functions.GetQBPlayers()) do
            table.insert(players, ply.PlayerData.source)
        end
        return players
    end
    return {}
end

-- ─── Society Money ─────────────────────────────
--  ESX: uses esx_addonaccount / esx_society
--  QBCore: uses Shared account (gang_account / job_account)

function GetSocietyMoney()
    if Framework.Type == 'esx' then
        local account = exports['esx_addonaccount']:getSharedAccount(Config.Society.account)
        return account and account.money or 0
    elseif Framework.Type == 'qbcore' then
        -- QBCore doesn't have a built-in society; store in DB instead
        return exports['qb-banking'] and exports['qb-banking']:GetJobAccount(Config.JobName) or 0
    end
    return 0
end

function AddSocietyMoney(amount)
    if Framework.Type == 'esx' then
        local account = exports['esx_addonaccount']:getSharedAccount(Config.Society.account)
        if account then account.addMoney(amount) end
    elseif Framework.Type == 'qbcore' then
        if exports['qb-banking'] then exports['qb-banking']:AddJobMoney(Config.JobName, amount) end
    end
end

function RemoveSocietyMoney(amount)
    if Framework.Type == 'esx' then
        local account = exports['esx_addonaccount']:getSharedAccount(Config.Society.account)
        if account then account.removeMoney(amount) end
    elseif Framework.Type == 'qbcore' then
        if exports['qb-banking'] then exports['qb-banking']:RemoveJobMoney(Config.JobName, amount) end
    end
end

-- ─── Notification ─────────────────────────────

function NotifyPlayer(source, msg, notifType)
    if Framework.Type == 'esx' then
        TriggerClientEvent('ESX:ShowNotification', source, msg)
    elseif Framework.Type == 'qbcore' then
        TriggerClientEvent('QBCore:Notify', source, msg, notifType or 'primary')
    end
end
