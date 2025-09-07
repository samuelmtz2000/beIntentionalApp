---
title: Quick Start
---

Local setup
- `pnpm db:migrate` — apply Prisma migrations
- `pnpm db:seed` — seed demo data
- `pnpm dev:api` — start API at `:4000`

Health check
```bash
curl http://localhost:4000/health
```

Auth
- v1 uses a single default user (`seed-user-1`) and no authentication.

