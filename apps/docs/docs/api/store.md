---
title: Store & Credits
---

Catalog
- List items from `GET /bad-habits` (the UI can show `coinCost` as the price).

Inventory
- `GET /me` returns `ownedBadHabits: [{ id, name, count }]` — number of credits owned per bad habit.

Buy
- POST `/store/bad-habits/:id/buy` buys one credit; duplicates allowed.
- Deducts coins by `coinCost`; writes `Transaction`; returns `{ ok: true, coins }`.

Consume on record
- When recording a bad habit, the server finds and deletes one credit row, if any, and avoids life loss.
- Without credits, life is reduced by `lifePenalty`.

