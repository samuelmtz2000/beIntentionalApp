---
title: Running Challenge (Game Over Recovery)
---

Per‑user running distance required to recover from Game Over. Default target is 42,195 meters (full marathon) and is configurable via user config.

Data
- User.runningChallengeTarget (meters)
- User.gameState: active | game_over | recovery
- User.gameOverAt, recoveryStartedAt, recoveryDistance, recoveryCompletedAt, totalGameOvers

Endpoints
- GET `/users/{id}/game-state`
  - Returns: `{ state, life, game_over_date, recovery_started_at, recovery_distance, recovery_target, recovery_percentage }`
- PUT `/users/{id}/recovery-progress`
  - Body: `{ distance: number }` cumulative meters since `game_over_date` or `recovery_started_at`
  - Returns: `{ recovery_distance, recovery_percentage, remaining_distance, is_complete }`
- POST `/users/{id}/complete-recovery`
  - Completes when `recovery_distance >= recovery_target`
  - Returns: `{ game_state: "active", life: 1000, recovery_completed_at, message }`

Configuration
- GET `/users/{id}/config` → includes `runningChallengeTarget`
- PUT `/users/{id}/config` → accepts `runningChallengeTarget` (min 1000, max 500000)

iOS Notes
- Game Over header shows skull; heart hidden
- Running Challenge modal shows target in km (dynamic)
- UI‑first completion: show confetti modal first, then POST complete‑recovery on dismiss

