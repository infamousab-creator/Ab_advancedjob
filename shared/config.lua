Config = {}

-- ================================================
--   FRAMEWORK DETECTION (auto or manual)
-- ================================================
Config.Framework = 'auto' -- 'auto' | 'esx' | 'qbcore'

-- ================================================
--   JOB SETTINGS
-- ================================================
Config.JobName     = 'mechanic'   -- must match your framework's job name
Config.JobLabel    = 'Mechanic'
Config.MinGrade    = 0            -- minimum grade to use the job menu
Config.BossGrade   = 3            -- grade considered "boss" for management

-- ================================================
--   DUTY SYSTEM
-- ================================================
Config.DutySystem  = true         -- enable on/off duty toggle
Config.DutyPay     = true         -- only pay salary when on duty

-- ================================================
--   SALARY
-- ================================================
Config.Salary = {
    enabled   = true,
    interval  = 10,   -- minutes between payments
    -- per-grade salary; keys must match grade indexes
    grades = {
        [0] = 500,
        [1] = 750,
        [2] = 1000,
        [3] = 1500,
    },
}

-- ================================================
--   SOCIETY / BOSS MENU
-- ================================================
Config.Society = {
    enabled     = true,
    account     = 'society_' .. 'mechanic',  -- society money account name
    taxPercent  = 10,  -- % tax taken from society withdrawals
}

-- ================================================
--   JOB LOCATIONS
-- ================================================
Config.Locations = {
    -- Main job NPC / menu trigger
    boss = {
        coords  = vector4(271.89, -1323.15, 28.25, 93.0),
        label   = 'Boss Menu',
        ped     = { model = 's_m_m_autoshop_02', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    },
    duty = {
        coords  = vector4(264.43, -1328.07, 28.25, 270.0),
        label   = 'Clock In / Out',
        ped     = { model = 's_m_m_autoshop_01', scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
    },
    stash = {
        coords  = vector4(267.12, -1318.44, 28.25, 180.0),
        label   = 'Job Stash',
    },
    garage = {
        coords  = vector4(251.12, -1316.97, 28.25, 270.0),
        label   = 'Job Garage',
        spawnCoords = vector4(248.16, -1317.0, 28.25, 90.0),
    },
}

-- ================================================
--   JOB VEHICLES (for job garage)
-- ================================================
Config.Vehicles = {
    [0] = { -- grade 0+
        { model = 'towtruck',  label = 'Tow Truck',   price = 0 },
        { model = 'flatbed',   label = 'Flatbed',     price = 0 },
    },
    [2] = { -- grade 2+
        { model = 'towtruck2', label = 'Tow Truck S', price = 0 },
    },
}

-- ================================================
--   JOB ITEMS / TOOLS
-- ================================================
Config.Tools = {
    { item = 'wrench',      label = 'Wrench',       grade = 0 },
    { item = 'screwdriver', label = 'Screwdriver',  grade = 0 },
    { item = 'toolbag',     label = 'Tool Bag',     grade = 1 },
}

-- ================================================
--   REPAIR SYSTEM
-- ================================================
Config.RepairSystem = {
    enabled      = true,
    requireItem  = true,   -- require item in inventory
    item         = 'wrench',
    engineRepair = true,
    bodyRepair   = true,
    repairTime   = 5000,   -- ms per repair action
    payPerRepair = 200,    -- money earned per vehicle repaired
}

-- ================================================
--   NOTIFICATION STYLE
-- ================================================
-- 'esx' | 'qbcore' | 'ox_lib' | 'custom'
Config.NotifyStyle = 'auto'

-- ================================================
--   BLIPS
-- ================================================
Config.Blips = {
    enabled = true,
    {
        coords  = vector3(271.89, -1323.15, 28.25),
        sprite  = 446,
        color   = 5,
        scale   = 0.8,
        label   = 'Mechanic Shop',
        display = 4,
    },
}

-- ================================================
--   INTERACTION DISTANCE
-- ================================================
Config.InteractDist = 2.0   -- metres from ped/marker to show prompt

-- ================================================
--   DEBUG
-- ================================================
Config.Debug = false
