import request from "supertest";
import { app } from "../src/index";

function todayKey(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

describe("Per-habit streaks", () => {
  const unique = `streaks-${Date.now()}`;
  let areaId = "";
  let goodId = "";
  let badId = "";

  it("creates area, good habit, bad habit", async () => {
    const area = await request(app).post("/areas").send({ name: `${unique}-area`, xpPerLevel: 100, levelCurve: "linear" });
    expect(area.status).toBe(200);
    areaId = area.body.id;

    const good = await request(app).post("/habits").send({ areaId, name: `${unique}-good`, xpReward: 5, coinReward: 1, isActive: true });
    expect(good.status).toBe(200);
    goodId = good.body.id;

    const bad = await request(app).post("/bad-habits").send({ name: `${unique}-bad`, lifePenalty: 1, controllable: true, coinCost: 0, isActive: true });
    expect(bad.status).toBe(200);
    badId = bad.body.id;
  });

  it("logs a good habit today and shows done in history", async () => {
    const comp = await request(app).post(`/actions/habits/${goodId}/complete`).send({});
    expect(comp.status).toBe(200);
    const today = todayKey();
    const hist = await request(app).get(`/streaks/habits/${goodId}/history`).query({ type: "good", from: today, to: today });
    expect(hist.status).toBe(200);
    expect(hist.body.history).toHaveLength(1);
    expect(hist.body.history[0].status).toBe("done");
  });

  it("records forgiven then unforgiven bad and returns forgiven/occurred markers", async () => {
    // buy one credit
    const buy = await request(app).post(`/store/bad-habits/${badId}/buy`).send({});
    expect(buy.status).toBe(200);
    // record forgiven
    const recForgiven = await request(app).post(`/actions/bad-habits/${badId}/record`).send({});
    expect(recForgiven.status).toBe(200);

    // record one more without credit (unforgiven)
    const rec = await request(app).post(`/actions/bad-habits/${badId}/record`).send({});
    expect(rec.status).toBe(200);

    const today = todayKey();
    const hist = await request(app).get(`/streaks/habits/${badId}/history`).query({ type: "bad", from: today, to: today });
    expect(hist.status).toBe(200);
    expect(hist.body.history).toHaveLength(1);
    expect(hist.body.history[0].status).toBe("occurred");
  });

  it("aggregates per-habit streaks", async () => {
    const today = todayKey();
    const agg = await request(app).get(`/streaks/habits`).query({ from: today, to: today });
    expect(agg.status).toBe(200);
    expect(Array.isArray(agg.body.items)).toBe(true);
    // Ensure our good and bad appear
    const foundGood = agg.body.items.find((i: any) => i.habitId === goodId && i.type === "good");
    const foundBad = agg.body.items.find((i: any) => i.habitId === badId && i.type === "bad");
    expect(foundGood).toBeTruthy();
    expect(foundBad).toBeTruthy();
  });
});

