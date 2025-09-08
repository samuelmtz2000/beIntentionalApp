import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
const DEFAULT_USER_ID = "seed-user-1";

async function main() {
  const user = await prisma.user.upsert({
    where: { id: DEFAULT_USER_ID },
    update: {},
    create: {
      id: DEFAULT_USER_ID,
      name: "Seed User",
      life: 100,
      coins: 0,
      level: 1,
      xp: 0,
      xpPerLevel: 100,
      levelCurve: "linear",
      levelMultiplier: 1.5,
      xpComputationMode: "logs",
    },
  });

  const health = await prisma.area.upsert({
    where: { id: "area-health" },
    update: {},
    create: { id: "area-health", name: "Health", userId: user.id, icon: "💪", xpPerLevel: 100, levelCurve: "linear" },
  });
  const learning = await prisma.area.upsert({
    where: { id: "area-learning" },
    update: {},
    create: { id: "area-learning", name: "Learning", userId: user.id, icon: "📚", xpPerLevel: 120, levelCurve: "exp" },
  });
  const finance = await prisma.area.upsert({
    where: { id: "area-finance" },
    update: {},
    create: { id: "area-finance", name: "Finance", userId: user.id, icon: "💰", xpPerLevel: 90, levelCurve: "linear" },
  });

  await prisma.goodHabit.upsert({
    where: { id: "habit-pushups" },
    update: {},
    create: { id: "habit-pushups", areaId: health.id, name: "Do 20 pushups", xpReward: 12, coinReward: 5, cadence: "daily" },
  });
  await prisma.goodHabit.upsert({
    where: { id: "habit-reading" },
    update: {},
    create: { id: "habit-reading", areaId: learning.id, name: "Read 10 pages", xpReward: 15, coinReward: 6, cadence: "daily" },
  });
  await prisma.goodHabit.upsert({
    where: { id: "habit-budget" },
    update: {},
    create: { id: "habit-budget", areaId: finance.id, name: "Track expenses", xpReward: 10, coinReward: 4, cadence: "daily" },
  });

  await prisma.badHabit.upsert({
    where: { id: "bad-junk-food" },
    update: {},
    create: { id: "bad-junk-food", areaId: health.id, name: "Eat junk food", lifePenalty: 5, controllable: false, coinCost: 0 },
  });
  await prisma.badHabit.upsert({
    where: { id: "bad-doomscroll" },
    update: {},
    create: { id: "bad-doomscroll", areaId: learning.id, name: "Doomscrolling", lifePenalty: 4, controllable: true, coinCost: 3 },
  });

  console.log("Seed complete");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
