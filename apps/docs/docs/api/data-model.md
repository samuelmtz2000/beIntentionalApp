---
title: Data Model
---

Prisma models (SQLite):

- User(id, name?, life=100, coins=0, avatar Json?)
- Area(id, userId, name, icon?, xpPerLevel=100, levelCurve)
- GoodHabit(id, areaId, name, xpReward, coinReward, cadence?, isActive)
- BadHabit(id, areaId?, name, lifePenalty, coinCost, isActive)
- AreaLevel(id, userId, areaId, level, xp) with unique (userId, areaId)
- HabitLog(id, userId, habitId, timestamp)
- BadHabitLog(id, userId, badHabitId, timestamp, avoidedPenalty)
- Transaction(id, userId, amount, type, meta?, timestamp)
- UserOwnedBadHabit(id, userId, badHabitId, purchasedAt)

Ownership/credits
- Each `UserOwnedBadHabit` row is one credit for a specific bad habit.
- Multiple rows for the same `(userId, badHabitId)` are allowed (inventory).

