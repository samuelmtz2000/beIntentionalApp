import request from "supertest";
import { app } from "../src/index";
import prisma from "../src/lib/prisma";

describe("Area exp leveling with multiplier", () => {
  beforeAll(async () => {
    // Ensure user is in active state and healthy
    await prisma.user.update({ where: { id: "seed-user-1" }, data: { gameState: "active", life: 1000 } });
  });
  it("applies exp multiplier for area progression", async () => {
    // Create area with exp curve and multiplier 2.0
    const areaRes = await request(app)
      .post("/areas")
      .send({ name: "Test Area EXP", xpPerLevel: 100, levelCurve: "exp", levelMultiplier: 2 });
    expect(areaRes.status).toBe(201);
    const areaId = areaRes.body.id as string;

    // Create habit in that area with xpReward 100
    const habitRes = await request(app)
      .post("/habits")
      .send({ areaId, name: "Do thing", xpReward: 100, coinReward: 0, isActive: true });
    expect(habitRes.status).toBe(201);
    const habitId = habitRes.body.id as string;

    // First completion: level 1 need=100, gain 100 -> level 2, xp 0
    const c1 = await request(app).post(`/actions/habits/${habitId}/complete`).send({});
    expect(c1.status).toBe(200);
    expect(c1.body.areaLevel.level).toBe(2);
    expect(c1.body.areaLevel.xp).toBe(0);

    // Second completion: level 2 need=200, gain 100 -> level 2, xp 100
    const c2 = await request(app).post(`/actions/habits/${habitId}/complete`).send({});
    expect(c2.status).toBe(200);
    expect(c2.body.areaLevel.level).toBe(2);
    expect(c2.body.areaLevel.xp).toBe(100);
  });
});
