---
title: Data Model
---

Prisma models (SQLite):

- User(id, name?, life=1000, coins=0, avatar Json?,
  level, xp, xpPerLevel=100, levelCurve, levelMultiplier=1.5, xpComputationMode,
  gameState, gameOverAt?, recoveryStartedAt?, recoveryDistance=0, recoveryCompletedAt?, totalGameOvers=0,
  runningChallengeTarget=42195)
- Area(id, userId, name, icon?, xpPerLevel=100, levelCurve, levelMultiplier=1.5)
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

## ER Diagram

```mermaid
erDiagram
  USER {
    string id PK
    string name
    int life
    int coins
    json avatar
    // Leveling
    int level
    int xp
    int xpPerLevel
    string levelCurve
    float levelMultiplier
    string xpComputationMode
    // Game Over & Running Challenge
    string gameState
    date gameOverAt
    date recoveryStartedAt
    int recoveryDistance
    date recoveryCompletedAt
    int totalGameOvers
    // Config
    int runningChallengeTarget
  }

  AREA {
    string id PK
    string userId FK
    string name
    string icon
    int xpPerLevel
    string levelCurve
    float levelMultiplier
  }

  GOODHABIT {
    string id PK
    string areaId FK
    string name
    int xpReward
    int coinReward
    string cadence
    boolean isActive
  }

  BADHABIT {
    string id PK
    string areaId FK
    string name
    int lifePenalty
    boolean controllable
    int coinCost
    boolean isActive
  }

  AREALEVEL {
    string id PK
    string userId FK
    string areaId FK
    int level
    int xp
  }

  HABITLOG {
    string id PK
    string userId FK
    string habitId FK
    date timestamp
  }

  BADHABITLOG {
    string id PK
    string userId FK
    string badHabitId FK
    date timestamp
    boolean avoidedPenalty
  }

  TRANSACTION {
    string id PK
    string userId FK
    int amount
    string type
    json meta
    date timestamp
  }

  USEROWNEDBADHABIT {
    string id PK
    string userId FK
    string badHabitId FK
    date purchasedAt
  }

  USER ||--o{ AREA : has
  USER ||--o{ AREALEVEL : tracks
  AREA ||--o{ AREALEVEL : progress
  AREA ||--o{ GOODHABIT : has
  AREA ||--o{ BADHABIT : has
  USER ||--o{ HABITLOG : writes
  GOODHABIT ||--o{ HABITLOG : logged
  USER ||--o{ BADHABITLOG : writes
  BADHABIT ||--o{ BADHABITLOG : logged
  USER ||--o{ TRANSACTION : has
  USER ||--o{ USEROWNEDBADHABIT : owns
  BADHABIT ||--o{ USEROWNEDBADHABIT : credited
```

Note: If the diagram does not render, enable Mermaid in Docusaurus by adding `markdown: { mermaid: true }` and the `"@docusaurus/theme-mermaid"` theme in `docusaurus.config.ts`.
