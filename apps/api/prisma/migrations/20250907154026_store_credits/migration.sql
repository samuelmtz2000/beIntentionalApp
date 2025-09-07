-- Drop unique index to allow multiple credit rows per user+badHabit
DROP INDEX IF EXISTS "UserOwnedBadHabit_userId_badHabitId_key";
