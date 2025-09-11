-- AlterTable
ALTER TABLE "Area" ADD COLUMN "deletedAt" DATETIME;

-- CreateIndex
CREATE INDEX "Area_deletedAt_idx" ON "Area"("deletedAt");
