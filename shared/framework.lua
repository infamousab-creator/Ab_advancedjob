-- ================================================
--   SHARED FRAMEWORK BRIDGE
--   Detects ESX or QBCore automatically
-- ================================================

Framework       = {}
Framework.Type  = nil

local function detectFramework()
    if Config.Framework ~= 'auto' then
        Framework.Type = Config.Framework
        return
    end
    if GetResourceState('es_extended') == 'started' then
        Framework.Type = 'esx'
    elseif GetResourceState('qb-core') == 'started' then
        Framework.Type = 'qbcore'
    else
        print('^1[advanced_job] ERROR: No supported framework detected!^7')
    end
end

detectFramework()

if Config.Debug then
    print('^3[advanced_job] Framework detected: ' .. tostring(Framework.Type) .. '^7')
end
