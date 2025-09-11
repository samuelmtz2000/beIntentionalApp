-- Add deletedAt columns and indexes for soft delete
ALTER TABLE "Area" ADD COLUMN "deletedAt" DATETIME;
CREATE INDEX IF NOT EXISTS "Area_deletedAt_idx" ON "Area" ("deletedAt");

ALTER TABLE "GoodHabit" ADD COLUMN "deletedAt" DATETIME;
CREATE INDEX IF NOT EXISTS "GoodHabit_deletedAt_idx" ON "GoodHabit" ("deletedAt");

ALTER TABLE "BadHabit" ADD COLUMN "deletedAt" DATETIME;
CREATE INDEX IF NOT EXISTS "BadHabit_deletedAt_idx" ON "BadHabit" ("deletedAt");

