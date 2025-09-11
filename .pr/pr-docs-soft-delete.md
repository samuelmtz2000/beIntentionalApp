Documents soft-delete + archive testing workflow and adds a smoke test script.

- Agents and API README updated
- Adds script: pnpm -F @habit-hero/api test:soft-delete

How to run
- pnpm db:migrate && pnpm db:seed && pnpm -F @habit-hero/api prisma generate
- pnpm -F @habit-hero/api test:soft-delete
