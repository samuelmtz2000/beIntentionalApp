import "../src/index"; // starts the server on :4000 when not NODE_ENV=test

type Res = { name: string; passed: boolean; expected: any; actual: any; notes?: string };

const BASE = process.env.BASE_URL || "http://localhost:4000";

async function get(path: string) {
  const r = await fetch(BASE + path);
  const text = await r.text();
  try { return { status: r.status, body: JSON.parse(text) }; } catch { return { status: r.status, body: text }; }
}
async function post(path: string, body?: any) {
  const r = await fetch(BASE + path, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body || {}) });
  const text = await r.text();
  try { return { status: r.status, body: JSON.parse(text) }; } catch { return { status: r.status, body: text }; }
}
async function del(path: string) {
  const r = await fetch(BASE + path, { method: "DELETE" });
  const text = await r.text();
  try { return { status: r.status, body: JSON.parse(text) }; } catch { return { status: r.status, body: text }; }
}

async function main() {
  const results: Res[] = [];

  // Health
  const h = await get("/health");
  results.push({ name: "GET /health", passed: h.status === 200 && h.body.ok === true, expected: { ok: true }, actual: h.body });

  // Seed profile
  const me = await get("/me");
  results.push({ name: "GET /me", passed: me.status === 200 && typeof me.body.life === "number", expected: { life: "number", coins: "number" }, actual: me.body });

  // Create Area
  const areaBody = { name: `Area SD ${Date.now()}`, icon: "leaf", xpPerLevel: 100, levelCurve: "linear" };
  const area = await post("/areas", areaBody);
  results.push({ name: "POST /areas", passed: area.status === 201, expected: 201, actual: area.status });

  // Create Habit in Area
  const habitBody = { areaId: area.body.id, name: `Habit SD ${Date.now()}`, xpReward: 10, coinReward: 1, cadence: undefined, isActive: true };
  const habit = await post("/habits", habitBody);
  results.push({ name: "POST /habits", passed: habit.status === 201, expected: 201, actual: habit.status });

  // Create Bad Habit in Area
  const badBody = { areaId: area.body.id, name: `Bad SD ${Date.now()}`, lifePenalty: 5, controllable: false, coinCost: 0, isActive: true };
  const bad = await post("/bad-habits", badBody);
  results.push({ name: "POST /bad-habits", passed: bad.status === 201, expected: 201, actual: bad.status });

  // Active lists include created
  const areas1 = await get("/areas");
  const habits1 = await get("/habits");
  const bads1 = await get("/bad-habits");
  results.push({ name: "GET /areas active", passed: areas1.status === 200 && areas1.body.some((a: any) => a.id === area.body.id), expected: "includes created area", actual: areas1.body.length });
  results.push({ name: "GET /habits active", passed: habits1.status === 200 && habits1.body.some((h: any) => h.id === habit.body.id), expected: "includes created habit", actual: habits1.body.length });
  results.push({ name: "GET /bad-habits active", passed: bads1.status === 200 && bads1.body.some((b: any) => b.id === bad.body.id), expected: "includes created bad habit", actual: bads1.body.length });

  // Soft delete habit
  const delHabit = await del(`/habits/${habit.body.id}`);
  results.push({ name: "DELETE /habits/:id (soft)", passed: delHabit.status === 204, expected: 204, actual: delHabit.status });

  // Verify habit hidden from active list and 404 by id
  const habits2 = await get("/habits");
  const habitById = await get(`/habits/${habit.body.id}`);
  results.push({ name: "GET /habits excludes archived", passed: !habits2.body.some((h: any) => h.id === habit.body.id), expected: "not present", actual: habits2.body.find((h: any) => h.id === habit.body.id) });
  results.push({ name: "GET /habits/:id returns 404 when archived", passed: habitById.status === 404, expected: 404, actual: habitById.status });

  // Archive listing contains habit
  const archive = await get("/archive");
  const inArchive = archive.status === 200 && Array.isArray(archive.body.habits) && archive.body.habits.some((h: any) => h.id === habit.body.id);
  results.push({ name: "GET /archive contains archived habit", passed: inArchive, expected: "archived in /archive.habits", actual: { counts: { areas: archive.body.areas.length, habits: archive.body.habits.length, badHabits: archive.body.badHabits.length } } });

  // Restore habit
  const restoreHabit = await post(`/habits/${habit.body.id}/restore`, {});
  results.push({ name: "POST /habits/:id/restore", passed: restoreHabit.status === 200, expected: 200, actual: restoreHabit.status });

  // Complete habit works
  const complete = await post(`/actions/habits/${habit.body.id}/complete`, {});
  results.push({ name: "POST /actions/habits/:id/complete (active)", passed: complete.status === 200, expected: 200, actual: complete.status });

  // Archive bad habit and verify action blocked
  await del(`/bad-habits/${bad.body.id}`);
  const recordBad = await post(`/actions/bad-habits/${bad.body.id}/record`, {});
  results.push({ name: "POST /actions/bad-habits/:id/record blocked when archived", passed: recordBad.status === 404, expected: 404, actual: recordBad.status });

  // Restore bad habit and buy is allowed
  const restoreBad = await post(`/bad-habits/${bad.body.id}/restore`, {});
  const buy = await post(`/store/bad-habits/${bad.body.id}/buy`, {});
  results.push({ name: "POST /bad-habits/:id/restore", passed: restoreBad.status === 200, expected: 200, actual: restoreBad.status });
  results.push({ name: "POST /store/bad-habits/:id/buy allowed when active", passed: buy.status === 200 || buy.status === 400, expected: "200 or 400 (insufficient coins)", actual: buy.status });

  // Archive area and verify excluded from active list, restore it
  await del(`/areas/${area.body.id}`);
  const areasAfterDel = await get("/areas");
  const areaById = await get(`/areas/${area.body.id}`);
  results.push({ name: "GET /areas excludes archived area", passed: !areasAfterDel.body.some((a: any) => a.id === area.body.id), expected: "not present", actual: areasAfterDel.body.length });
  results.push({ name: "GET /areas/:id returns 404 when archived", passed: areaById.status === 404, expected: 404, actual: areaById.status });
  const restoreArea = await post(`/areas/${area.body.id}/restore`, {});
  results.push({ name: "POST /areas/:id/restore", passed: restoreArea.status === 200, expected: 200, actual: restoreArea.status });

  // Output concise summary
  const summary = results.map((r) => ({ name: r.name, passed: r.passed, expected: r.expected, actual: r.actual })).slice();
  console.log(JSON.stringify(summary, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
