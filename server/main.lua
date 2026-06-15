-- ================================================
--   SERVER MAIN
-- ================================================

local salaryTimers = {}

-- ─── Player Connect / Disconnect ───────────────

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    local identifier = GetIdentifier(src)
    if identifier then
        DB.InitPlayer(identifier)
        DB.LoadDuty(identifier, function() end)
    end
    deferrals.done()
end)

AddEventHandler('playerDropped', function()
    local src        = source
    local identifier = GetIdentifier(src)
    if identifier then
        -- persist duty state already handled in DB.SetDuty
        salaryTimers[identifier] = nil
    end
end)

-- ─── Duty System ───────────────────────────────

RegisterNetEvent('advanced_job:setDuty', function(state)
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end
    if not HasJob(src) then
        NotifyPlayer(src, 'You are not a ' .. Config.JobLabel, 'error')
        return
    end

    DB.SetDuty(identifier, state)
    TriggerClientEvent('advanced_job:dutyChanged', src, state)

    if state and Config.Salary.enabled and Config.DutyPay then
        StartSalaryTimer(src, identifier)
    else
        salaryTimers[identifier] = false
    end

    if Config.Debug then
        print('[advanced_job] ' .. identifier .. ' duty: ' .. tostring(state))
    end
end)

RegisterNetEvent('advanced_job:syncDuty', function()
    local src        = source
    local identifier = GetIdentifier(src)
    if not identifier then return end
    local state = DB.GetDuty(identifier)
    TriggerClientEvent('advanced_job:syncDutyState', src, state)
end)

-- ─── Salary System ─────────────────────────────

function StartSalaryTimer(src, identifier)
    if salaryTimers[identifier] then return end
    salaryTimers[identifier] = true

    CreateThread(function()
        while salaryTimers[identifier] do
            Wait(Config.Salary.interval * 60 * 1000)
            if salaryTimers[identifier] and HasJob(src) then
                local job    = GetJob(src)
                local grade  = job and job.grade or 0
                local amount = Config.Salary.grades[grade] or Config.Salary.grades[0] or 500

                AddMoney(src, amount, 'salary')
                TriggerClientEvent('advanced_job:receivePaycheck', src, amount)
            else
                salaryTimers[identifier] = false
            end
        end
    end)
end

-- Also start salary for players not using DutyPay
if not Config.DutyPay and Config.Salary.enabled then
    CreateThread(function()
        while true do
            Wait(Config.Salary.interval * 60 * 1000)
            for _, src in ipairs(GetAllPlayers()) do
                if HasJob(src) then
                    local job    = GetJob(src)
                    local grade  = job and job.grade or 0
                    local amount = Config.Salary.grades[grade] or Config.Salary.grades[0] or 500
                    AddMoney(src, amount, 'salary')
                    TriggerClientEvent('advanced_job:receivePaycheck', src, amount)
                end
            end
        end
    end)
end

-- ─── Boss Menu ─────────────────────────────────

RegisterNetEvent('advanced_job:fetchBossData', function()
    local src = source
    if not IsBoss(src) then return end

    DB.GetEmployees(function(employees)
        local society = Config.Society.enabled and GetSocietyMoney() or 0
        TriggerClientEvent('advanced_job:openBossMenu', src, {
            employees = employees,
            society   = society,
            grades    = Config.Salary.grades,
            bossGrade = Config.BossGrade,
        })
    end)
end)

RegisterNetEvent('advanced_job:setPlayerGrade', function(citizenid, grade)
    local src = source
    if not IsBoss(src) then return end
    if type(grade) ~= 'number' then return end

    -- Find online player
    for _, pid in ipairs(GetAllPlayers()) do
        local id = GetIdentifier(pid)
        if id == citizenid then
            SetJob(pid, Config.JobName, grade)
            NotifyPlayer(pid, 'Your grade has been updated to ' .. grade, 'success')
            NotifyPlayer(src, 'Grade updated successfully.', 'success')
            return
        end
    end
    -- Offline: update DB directly
    if Framework.Type == 'esx' then
        MySQL.update('UPDATE users SET job_grade = ? WHERE identifier = ? AND job = ?',
            { grade, citizenid, Config.JobName })
    elseif Framework.Type == 'qbcore' then
        MySQL.update([[
            UPDATE players
            SET job = JSON_SET(job, '$.grade.level', ?)
            WHERE citizenid = ?
        ]], { grade, citizenid })
    end
    NotifyPlayer(src, 'Offline player grade updated.', 'success')
end)

RegisterNetEvent('advanced_job:fireEmployee', function(citizenid)
    local src = source
    if not IsBoss(src) then return end

    for _, pid in ipairs(GetAllPlayers()) do
        local id = GetIdentifier(pid)
        if id == citizenid then
            SetJob(pid, 'unemployed', 0)
            NotifyPlayer(pid, 'You have been fired from ' .. Config.JobLabel, 'error')
            NotifyPlayer(src, 'Employee fired.', 'success')
            return
        end
    end
    if Framework.Type == 'esx' then
        MySQL.update("UPDATE users SET job = 'unemployed', job_grade = 0 WHERE identifier = ?", { citizenid })
    elseif Framework.Type == 'qbcore' then
        MySQL.update([[
            UPDATE players
            SET job = JSON_SET(job,
                '$.name', 'unemployed',
                '$.grade.level', 0,
                '$.grade.name', 'Unemployed')
            WHERE citizenid = ?
        ]], { citizenid })
    end
    NotifyPlayer(src, 'Offline player fired.', 'success')
end)

RegisterNetEvent('advanced_job:hireEmployee', function(citizenid)
    local src = source
    if not IsBoss(src) then return end

    for _, pid in ipairs(GetAllPlayers()) do
        local id = GetIdentifier(pid)
        if id == citizenid then
            SetJob(pid, Config.JobName, 0)
            NotifyPlayer(pid, 'You have been hired as ' .. Config.JobLabel, 'success')
            NotifyPlayer(src, 'Employee hired.', 'success')
            return
        end
    end
    NotifyPlayer(src, 'Player must be online to be hired.', 'error')
end)

-- ─── Society ───────────────────────────────────

RegisterNetEvent('advanced_job:societyWithdraw', function(amount)
    local src = source
    if not IsBoss(src) then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local balance = GetSocietyMoney()
    if balance < amount then
        NotifyPlayer(src, 'Insufficient funds in society account.', 'error')
        return
    end

    local tax  = math.floor(amount * (Config.Society.taxPercent / 100))
    local net  = amount - tax
    RemoveSocietyMoney(amount)
    AddMoney(src, net, 'society-withdrawal')
    NotifyPlayer(src, ('Withdrew $%d (tax: $%d, received: $%d)'):format(amount, tax, net), 'success')
end)

RegisterNetEvent('advanced_job:societyDeposit', function(amount)
    local src = source
    if not HasJob(src) then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    -- Remove from player (basic check; expand as needed)
    if Framework.Type == 'esx' then
        local ply = GetPlayer(src)
        if not ply or ply.getMoney() < amount then
            NotifyPlayer(src, 'Not enough money.', 'error')
            return
        end
        ply.removeMoney(amount)
    elseif Framework.Type == 'qbcore' then
        local ply = GetPlayer(src)
        if not ply or not ply.Functions.RemoveMoney('cash', amount, 'society-deposit') then
            NotifyPlayer(src, 'Not enough money.', 'error')
            return
        end
    end

    AddSocietyMoney(amount)
    NotifyPlayer(src, 'Deposited $' .. amount .. ' into society account.', 'success')
end)

-- ─── Stash ─────────────────────────────────────

RegisterNetEvent('advanced_job:openStash', function()
    local src = source
    if not HasJob(src) then return end
    local id  = 'advanced_job_stash_' .. Config.JobName

    if Framework.Type == 'esx' then
        TriggerClientEvent('esx_inventoryhud:openInventory', src) -- example
    elseif Framework.Type == 'qbcore' then
        TriggerClientEvent('inventory:client:OpenInventory', src, { name = id, label = Config.JobLabel .. ' Stash', maxWeight = 100000, slots = 50 })
    end
end)

-- ─── Vehicle Garage ────────────────────────────

local spawnedVehicles = {}

RegisterNetEvent('advanced_job:requestVehicle', function(model)
    local src = source
    if not HasJob(src) then return end

    local plate = 'JOB' .. math.random(10000, 99999)
    spawnedVehicles[GetIdentifier(src)] = { model = model, plate = plate }
    TriggerClientEvent('advanced_job:spawnVehicle', src, model, plate)
end)

-- ─── Repair Payment ────────────────────────────

RegisterNetEvent('advanced_job:repairComplete', function(amount)
    local src = source
    if not HasJob(src) then return end
    amount = tonumber(amount) or 0
    if amount > 0 then
        AddMoney(src, amount, 'vehicle-repair')
    end
end)

-- ─── SQL Setup Helper ──────────────────────────

CreateThread(function()
    Wait(500)
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `advanced_job_duty` (
            `identifier` VARCHAR(60) NOT NULL,
            `onduty`     TINYINT(1)  NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
end)
