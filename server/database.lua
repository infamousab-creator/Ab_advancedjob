-- ================================================
--   SERVER DATABASE
--   Uses oxmysql; swap for mysql-async if needed
-- ================================================

DB = {}

-- Store duty state per identifier
local dutyCache = {}

function DB.SetDuty(identifier, state)
    dutyCache[identifier] = state
    -- Persist to DB (optional — comment out if you don't want persistence)
    MySQL.update('UPDATE `advanced_job_duty` SET `onduty` = ? WHERE `identifier` = ?', { state and 1 or 0, identifier })
end

function DB.GetDuty(identifier)
    return dutyCache[identifier] or false
end

function DB.LoadDuty(identifier, cb)
    MySQL.single('SELECT `onduty` FROM `advanced_job_duty` WHERE `identifier` = ?', { identifier }, function(row)
        local state = row and row.onduty == 1 or false
        dutyCache[identifier] = state
        if cb then cb(state) end
    end)
end

function DB.InitPlayer(identifier)
    MySQL.insert('INSERT IGNORE INTO `advanced_job_duty` (`identifier`, `onduty`) VALUES (?, 0)', { identifier })
end

-- ─── Get all employees from framework DB ──────

function DB.GetEmployees(cb)
    if Framework.Type == 'esx' then
        MySQL.query([[
            SELECT u.identifier, u.firstname, u.lastname, j.grade, j.grade_label
            FROM users u
            JOIN jobs j ON j.name = ? AND j.grade = u.job_grade
            WHERE u.job = ?
        ]], { Config.JobName, Config.JobName }, function(rows)
            cb(rows or {})
        end)
    elseif Framework.Type == 'qbcore' then
        MySQL.query([[
            SELECT citizenid AS identifier,
                   JSON_UNQUOTE(JSON_EXTRACT(charinfo,'$.firstname')) AS firstname,
                   JSON_UNQUOTE(JSON_EXTRACT(charinfo,'$.lastname'))  AS lastname,
                   JSON_UNQUOTE(JSON_EXTRACT(job,'$.grade.level'))    AS grade,
                   JSON_UNQUOTE(JSON_EXTRACT(job,'$.grade.name'))     AS grade_label
            FROM players
            WHERE JSON_UNQUOTE(JSON_EXTRACT(job,'$.name')) = ?
        ]], { Config.JobName }, function(rows)
            cb(rows or {})
        end)
    end
end
