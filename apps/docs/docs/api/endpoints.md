---
title: Endpoints
---

Health
- GET `/health` → `{ ok: true }`

Profile
- GET `/me` → returns global stats and per‑area progress. Example:
```
{
  "life": 100,
  "coins": 12,
  "level": 2,
  "xp": 15,
  "xpPerLevel": 100,
  "config": { "levelCurve": "exp", "levelMultiplier": 1.5, "xpComputationMode": "logs" },
  "areas": [ { "areaId": "area-health", "name": "Health", "level": 1, "xp": 12, "xpPerLevel": 100 } ],
  "ownedBadHabits": [ { "id": "bad-doomscroll", "name": "Doomscrolling", "count": 2 } ]
}
```

Areas `/areas`
- GET — list
- GET `/:id` — get by id
- POST — create `{ name, icon?, xpPerLevel>=10, levelCurve: "linear"|"exp", levelMultiplier>=1? }`
- PUT `/:id` — update (partial)
- DELETE `/:id` — delete

Good Habits `/habits`
- GET — list (includes `area`)
- GET `/:id` — get by id (includes `area`)
- POST — create `{ areaId, name, xpReward>=1, coinReward>=0, cadence?, isActive }`
- PUT `/:id` — update (partial)
- DELETE `/:id` — delete

Bad Habits `/bad-habits`
- GET — list (includes `area`)
- GET `/:id` — get by id (includes `area`)
- POST — create `{ areaId?, name, lifePenalty>=1, coinCost>=0, isActive }`
- PUT `/:id` — update (partial)
- DELETE `/:id` — delete

Store `/store`
- POST `/store/bad-habits/:id/buy` — buy 1 credit for a bad habit (deduct coins by `coinCost`) — duplicates allowed

Users `/users`
- GET `/users/:id/config` → `{ xpPerLevel, levelCurve, levelMultiplier, xpComputationMode }`
- PUT `/users/:id/config` → update config; body `{ xpPerLevel>=10, levelCurve: "linear"|"exp", levelMultiplier>=1, xpComputationMode: "logs"|"stored" }`

Actions `/actions`
- POST `/actions/habits/:id/complete` → apply XP, earn coins; creates `HabitLog` + `Transaction`. Global XP/level behavior:
  - logs (default): user global XP/level are computed from history; stored counters are not updated on completion.
  - stored: user global XP/level counters are incremented on completion.
- POST `/actions/bad-habits/:id/record` → if credit exists, consume 1 and avoid life loss; else reduce life
