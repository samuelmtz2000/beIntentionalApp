import request from "supertest";
import { app } from "../src/index";
import prisma from "../src/lib/prisma";

describe("Global user leveling", () => {
  beforeAll(async () => {
    await prisma.user.update({ where: { id: "seed-user-1" }, data: { gameState: "active", life: 1000 } });
  });
  it("/me includes global level/xp/xpPerLevel", async () => {
    const res = await request(app).get("/me");
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty("level");
    expect(res.body).toHaveProperty("xp");
    expect(res.body).toHaveProperty("xpPerLevel");
  });

  it("completing habit increases user xp (and possibly level)", async () => {
    // Ensure active right before action to avoid cross-test interference
    await prisma.user.update({ where: { id: "seed-user-1" }, data: { gameState: "active", life: 1000 } });
    // Ensure stored XP mode for deterministic assertions
    await request(app)
      .put(`/users/seed-user-1/config`)
      .send({ xpPerLevel: 100, levelCurve: "linear", levelMultiplier: 1.5, xpComputationMode: "stored" });

    // Read profile
    const before = await request(app).get("/me");
    expect(before.status).toBe(200);
    const xpBefore = before.body.xp as number;
    const levelBefore = before.body.level as number;
    const perLevel = before.body.xpPerLevel as number;

    // Use a known seeded habit id if available
    const habits = await request(app).get("/habits");
    expect(habits.status).toBe(200);
    const habit = (habits.body as any[])[0];
    expect(habit).toBeTruthy();

    const complete = await request(app).post(`/actions/habits/${habit.id}/complete`).send({});
    expect(complete.status).toBe(200);

    const after = await request(app).get("/me");
    expect(after.status).toBe(200);
    const xpAfter = after.body.xp as number;
    const levelAfter = after.body.level as number;

    // xp should move forward; with wrap on level up
    expect(levelAfter === levelBefore || levelAfter === levelBefore + 1).toBe(true);
    if (levelAfter === levelBefore) {
      expect(xpAfter).toBeGreaterThan(xpBefore);
    } else {
      // leveled up: xpAfter should be less than perLevel
      expect(xpAfter).toBeGreaterThanOrEqual(0);
      expect(xpAfter).toBeLessThan(perLevel);
    }
  });
});
