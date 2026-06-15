# Advanced Job System — FiveM
**Compatible with ESX & QBCore** (auto-detected)

---

## Features
| Feature | Details |
|---|---|
| Dual framework support | ESX & QBCore — auto-detected at runtime |
| On/Off Duty system | Toggleable, persists across reconnects |
| Salary system | Per-grade, configurable interval, duty-aware |
| Boss management UI | Hire, fire, set grade (online & offline players) |
| Society account | Deposit / withdraw with configurable tax |
| Job Garage | Grade-locked vehicle spawning |
| Job Stash | Shared inventory (requires esx_inventoryhud / qb-inventory) |
| Repair system | Pay-per-repair, item requirement, configurable timings |
| Map blips | Configurable |
| Job NPC peds | Auto-spawned at configured coordinates |
| Persistent duty state | Stored in MySQL |

---

## Installation

### 1. Drop the resource
```
resources/
  [jobs]/
    advanced_job/
```

### 2. Import the SQL
Run `install.sql` in your database.

### 3. Register the job in your framework
**ESX** — add via `esx_jobs` or your database:
```sql
INSERT INTO jobs (name, label) VALUES ('mechanic', 'Mechanic');
INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female)
VALUES
  ('mechanic', 0, 'trainee',  'Trainee',   500,  '{}', '{}'),
  ('mechanic', 1, 'mech',     'Mechanic',  750,  '{}', '{}'),
  ('mechanic', 2, 'senior',   'Senior',    1000, '{}', '{}'),
  ('mechanic', 3, 'boss',     'Boss',      1500, '{}', '{}');
```

**QBCore** — add to `qb-core/shared/jobs.lua`:
```lua
['mechanic'] = {
    label = 'Mechanic',
    defaultDuty = false,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Trainee', payment = 500 },
        ['1'] = { name = 'Mechanic', payment = 750 },
        ['2'] = { name = 'Senior',   payment = 1000 },
        ['3'] = { name = 'Boss',     payment = 1500 },
    },
},
```

### 4. Start the resource
Add to your `server.cfg`:
```
ensure advanced_job
```

---

## Configuration (`shared/config.lua`)
All settings live in `Config` — coordinates, salary, grades, vehicles, blips, etc. Every option is documented inline.

---

## Dependencies
| Dependency | Required? | Notes |
|---|---|---|
| `es_extended` | If using ESX | Auto-detected |
| `qb-core` | If using QBCore | Auto-detected |
| `oxmysql` | **Required** | Used for DB; swap calls for `mysql-async` if needed |
| `esx_addonaccount` | ESX only, optional | Society money |
| `qb-banking` | QBCore only, optional | Job account |
| `ox_lib` | Optional | Better notifications |

---

## Key Bindings (client)
| Key | Action |
|---|---|
| `E` | Interact with NPC / location |
| `G` | Repair nearby vehicle |
| `Escape` | Close UI |

---

## Customisation Tips
- **Change job**: update `Config.JobName` and `Config.JobLabel`
- **Add vehicles**: extend `Config.Vehicles` table (key = minimum grade)
- **Replace target system**: swap the distance-check loop in `client/main.lua` with `ox_target` or `qb-target` exports
- **Notifications**: set `Config.NotifyStyle` to `'ox_lib'` for styled toasts
