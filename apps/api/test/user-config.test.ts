import request from "supertest";
import { app } from "../src/index";

const USER_ID = "seed-user-1";

describe("User config routes", () => {
  it("GET /users/:id/config returns config", async () => {
    const res = await request(app).get(`/users/${USER_ID}/config`);
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty("xpPerLevel");
    expect(res.body).toHaveProperty("levelCurve");
    expect(res.body).toHaveProperty("levelMultiplier");
    expect(res.body).toHaveProperty("xpComputationMode");
  });

  it("PUT /users/:id/config updates config", async () => {
    const res = await request(app)
      .put(`/users/${USER_ID}/config`)
      .send({ xpPerLevel: 120, levelCurve: "exp", levelMultiplier: 2, xpComputationMode: "logs" });
    expect(res.status).toBe(200);
    const get = await request(app).get(`/users/${USER_ID}/config`);
    expect(get.body.xpPerLevel).toBe(120);
    expect(get.body.levelCurve).toBe("exp");
    expect(get.body.levelMultiplier).toBe(2);
    expect(get.body.xpComputationMode).toBe("logs");
  });
});

