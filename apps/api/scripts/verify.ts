import request from "supertest";
import { app } from "../src/index";

async function main() {
  const health = await request(app).get("/health");
  console.log("/health:", health.status, health.body);

  const me = await request(app).get("/me");
  console.log("/me:", me.status, me.body);

  const habits = await request(app).get("/habits");
  console.log("/habits:", habits.status, Array.isArray(habits.body) ? habits.body.length : habits.body);

  const store = await request(app).get("/store/controlled-bad-habits");
  console.log("/store/controlled-bad-habits:", store.status, Array.isArray(store.body) ? store.body.length : store.body);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
