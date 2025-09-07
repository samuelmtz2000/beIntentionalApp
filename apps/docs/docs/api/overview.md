---
title: Overview
---

The Habit Hero API powers the gamified habit manager. It exposes JSON endpoints for Areas, Good Habits, Bad Habits, level progression, store purchases (credits), and logs.

- Base URL (local): `http://localhost:4000`
- Media type: `application/json`
- Errors: 400 for validation, 404 for missing resources
- Default user (no auth v1): `seed-user-1`

Key features
- Areas track XP/level with configurable curves
- Good habits grant XP + coins on completion
- Bad habits apply life penalty unless a credit is consumed
- Store allows buying credits per bad habit using coins (`coinCost`)
- Profile aggregates owned credits by bad habit

Useful links
- Swagger UI: `http://localhost:4000/docs`
- Dev Tester: `http://localhost:4000/tester`

