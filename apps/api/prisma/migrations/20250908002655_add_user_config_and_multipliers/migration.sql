-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Area" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "icon" TEXT,
    "xpPerLevel" INTEGER NOT NULL DEFAULT 100,
    "levelCurve" TEXT NOT NULL DEFAULT 'linear',
    "levelMultiplier" REAL NOT NULL DEFAULT 1.5,
    CONSTRAINT "Area_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Area" ("icon", "id", "levelCurve", "name", "userId", "xpPerLevel") SELECT "icon", "id", "levelCurve", "name", "userId", "xpPerLevel" FROM "Area";
DROP TABLE "Area";
ALTER TABLE "new_Area" RENAME TO "Area";
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
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_User" ("avatar", "coins", "createdAt", "id", "level", "levelCurve", "life", "name", "xp", "xpPerLevel") SELECT "avatar", "coins", "createdAt", "id", "level", "levelCurve", "life", "name", "xp", "xpPerLevel" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
