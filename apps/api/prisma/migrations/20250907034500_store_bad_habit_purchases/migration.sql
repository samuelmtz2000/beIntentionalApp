-- Remove cosmetics and switch to owned bad habits; rename BadHabitLog column
PRAGMA foreign_keys=OFF;

-- Recreate BadHabitLog with avoidedPenalty instead of paidWithCoins
CREATE TABLE "_new_BadHabitLog" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "badHabitId" TEXT NOT NULL,
    "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "avoidedPenalty" BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "BadHabitLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "BadHabitLog_badHabitId_fkey" FOREIGN KEY ("badHabitId") REFERENCES "BadHabit" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

INSERT INTO "_new_BadHabitLog" ("id","userId","badHabitId","timestamp","avoidedPenalty")
  SELECT "id","userId","badHabitId","timestamp", COALESCE("paidWithCoins", 0) FROM "BadHabitLog";

DROP TABLE "BadHabitLog";
ALTER TABLE "_new_BadHabitLog" RENAME TO "BadHabitLog";

-- Drop cosmetics tables if they exist
DROP TABLE IF EXISTS "UserCosmetic";
DROP TABLE IF EXISTS "Cosmetic";

-- Create ownership table for controlled bad habits
CREATE TABLE "UserOwnedBadHabit" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "badHabitId" TEXT NOT NULL,
    "purchasedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "UserOwnedBadHabit_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "UserOwnedBadHabit_badHabitId_fkey" FOREIGN KEY ("badHabitId") REFERENCES "BadHabit" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "UserOwnedBadHabit_userId_badHabitId_key" ON "UserOwnedBadHabit"("userId","badHabitId");

PRAGMA foreign_keys=ON;

