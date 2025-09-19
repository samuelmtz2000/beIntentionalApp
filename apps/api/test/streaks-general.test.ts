import request from "supertest";
import { app } from "../src/index";

function todayKey(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

describe("General streak — unforgiven vs forgiven bad logs", () => {
  const badId = `bad-streak-test-${Date.now()}`;

  it("marks day as unforgiven when recording without credit (breaks streak)", async () => {
    // Create a bad habit
    const createBad = await request(app).post("/bad-habits").send({ name: badId, lifePenalty: 1, controllable: true, coinCost: 0, isActive: true });
    expect(createBad.status).toBe(200);

    // Record occurrence without buying credit
    const record = await request(app).post(`/actions/bad-habits/${createBad.body.id}/record`).send({});
    expect(record.status).toBe(200);
    expect(typeof record.body.user.life).toBe("number");

    // Fetch general streak for today
    const today = todayKey();
    const streak = await request(app).get(`/streaks/general?from=${today}&to=${today}`);
    expect(streak.status).toBe(200);
    expect(streak.body.days).toHaveLength(1);
    const day = streak.body.days[0];
    expect(day.date).toBe(today);
    expect(day.hasUnforgivenBad).toBe(true);
    expect(day.daySuccess).toBe(false);
  });

  it("treated as neutral when using a credit (avoidedPenalty=true)", async () => {
    // Create a bad habit
    const createBad = await request(app).post("/bad-habits").send({ name: `${badId}-forgiven`, lifePenalty: 1, controllable: true, coinCost: 0, isActive: true });
    expect(createBad.status).toBe(200);

    // Buy one credit
    const buy = await request(app).post(`/store/bad-habits/${createBad.body.id}/buy`).send({});
    expect(buy.status).toBe(200);

    // Record occurrence; credit should be consumed and avoid penalty
    const record = await request(app).post(`/actions/bad-habits/${createBad.body.id}/record`).send({});
    expect(record.status).toBe(200);
    // For a forgiven event, life does not decrease; we only assert endpoint shape here
    expect(typeof record.body.user.life).toBe("number");

    // Fetch general streak for today and ensure no unforgiven flag set by this log
    const today = todayKey();
    const streak = await request(app).get(`/streaks/general?from=${today}&to=${today}`);
    expect(streak.status).toBe(200);
    expect(streak.body.days).toHaveLength(1);
    const day = streak.body.days[0];
    expect(day.date).toBe(today);
    expect(day.hasUnforgivenBad).toBe(false);
  });
});

