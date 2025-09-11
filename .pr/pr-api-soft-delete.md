Adds soft delete (deletedAt) for Area/GoodHabit/BadHabit with indexes.

- Default GETs exclude archived; unified GET /archive lists archived items by type
- Restore endpoints: POST /areas/:id/restore, /habits/:id/restore, /bad-habits/:id/restore
- Guards actions/store/me against archived; validate active area on create/update

Migration
- pnpm db:migrate && pnpm -F @habit-hero/api prisma generate

Test plan
- pnpm db:seed
- pnpm -F @habit-hero/api test:soft-delete (prints JSON summary; all steps should pass)
