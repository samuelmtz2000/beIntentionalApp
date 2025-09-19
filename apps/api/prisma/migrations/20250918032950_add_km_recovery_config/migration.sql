-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT,
    "life" INTEGER NOT NULL DEFAULT 100,
    "coins" INTEGER NOT NULL DEFAULT 0,
    "avatar" JSONB,
    "level" INTEGER NOT NULL DEFAULT 1,
    "xp" INTEGER NOT NULL DEFAULT 0,
    "xpPerLevel" INTEGER NOT NULL DEFAULT 100,
    "levelCurve" TEXT NOT NULL DEFAULT 'linear',
    "levelMultiplier" REAL NOT NULL DEFAULT 1.5,
    "xpComputationMode" TEXT NOT NULL DEFAULT 'logs',
    "gameState" TEXT NOT NULL DEFAULT 'active',
    "gameOverAt" DATETIME,
    "recoveryStartedAt" DATETIME,
    "recoveryDistance" INTEGER NOT NULL DEFAULT 0,
    "recoveryCompletedAt" DATETIME,
    "totalGameOvers" INTEGER NOT NULL DEFAULT 0,
    "runningChallengeTarget" INTEGER NOT NULL DEFAULT 42195,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_User" ("avatar", "coins", "createdAt", "gameOverAt", "gameState", "id", "level", "levelCurve", "levelMultiplier", "life", "name", "recoveryCompletedAt", "recoveryDistance", "recoveryStartedAt", "totalGameOvers", "xp", "xpComputationMode", "xpPerLevel") SELECT "avatar", "coins", "createdAt", "gameOverAt", "gameState", "id", "level", "levelCurve", "levelMultiplier", "life", "name", "recoveryCompletedAt", "recoveryDistance", "recoveryStartedAt", "totalGameOvers", "xp", "xpComputationMode", "xpPerLevel" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
