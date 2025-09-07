import request from "supertest";
import { app } from "../src/index";

async function main() {
  const health = await request(app).get("/health");
  console.log("/health:", health.status, health.body);

  const me = await request(app).get("/me");
  console.log("/me:", me.status, me.body);

  const habits = await request(app).get("/habits");
  console.log("/habits:", habits.status, Array.isArray(habits.body) ? habits.body.length : habits.body);

  const cosmetics = await request(app).get("/store/cosmetics");
  console.log("/store/cosmetics:", cosmetics.status, Array.isArray(cosmetics.body) ? cosmetics.body.length : cosmetics.body);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

