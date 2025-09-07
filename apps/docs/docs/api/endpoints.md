---
title: Endpoints
---

Health
- GET `/health` → `{ ok: true }`

Profile
- GET `/me` → `{ life, coins, areas: [...], ownedBadHabits: [{ id, name, count }] }`

Areas `/areas`
- GET — list
- GET `/:id` — get by id
- POST — create `{ name, icon?, xpPerLevel>=10, levelCurve: "linear"|"exp" }`
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

Actions `/actions`
- POST `/actions/habits/:id/complete` → apply XP, earn coins; creates `HabitLog` + `Transaction`
- POST `/actions/bad-habits/:id/record` → if credit exists, consume 1 and avoid life loss; else reduce life

