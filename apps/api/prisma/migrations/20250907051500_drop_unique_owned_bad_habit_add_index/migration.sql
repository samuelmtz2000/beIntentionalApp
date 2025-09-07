-- Drop the unique constraint on (userId,badHabitId) so multiple purchases are allowed
PRAGMA foreign_keys=OFF;

-- SQLite doesn't support dropping indexes by constraint name unless it exists; attempt to drop if present
DROP INDEX IF EXISTS "UserOwnedBadHabit_userId_badHabitId_key";

-- Recreate index as non-unique for faster lookups
CREATE INDEX IF NOT EXISTS "UserOwnedBadHabit_userId_badHabitId_idx" ON "UserOwnedBadHabit"("userId","badHabitId");

PRAGMA foreign_keys=ON;

