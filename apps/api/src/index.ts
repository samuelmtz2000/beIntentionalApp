import "dotenv/config";
import express from "express";
import helmet from "helmet";
import cors from "cors";
import rateLimit from "express-rate-limit";
import api from "./router/index.js";
import areas from "./router/areas.js";
import { exec } from "node:child_process";
import { createRequire } from "node:module";
import spec from "./openapi.js";

export const app = express();
app.use(express.json());
app.use(helmet());
app.use(cors());
app.use(rateLimit({ windowMs: 60_000, max: 120 }));

app.get("/health", (_req, res) => res.json({ ok: true }));
// Debug: log router stack length
// @ts-ignore
console.log("Router stack length:", (api as any)?.stack?.length);
app.use(api);
app.use("/areas", areas);

// Swagger UI (interactive API tester) at /docs
const require = createRequire(import.meta.url);
// eslint-disable-next-line @typescript-eslint/no-var-requires
const swaggerUi = require("swagger-ui-express");
app.use("/docs", swaggerUi.serve, swaggerUi.setup(spec));

app.get("/__routes", (req, res) => {
  const routes: string[] = [];
  // @ts-ignore
  const print = (stack: any[], prefix = "") => {
    for (const layer of stack) {
      if (layer.route && layer.route.path) {
        const methods = Object.keys(layer.route.methods || {}).join(",");
        routes.push(`${prefix}${layer.route.path} [${methods}]`);
      } else if (layer.name === "router" && layer.handle?.stack) {
        const p = layer.regexp?.fast_slash
          ? prefix
          : `${prefix}${layer.regexp?.source || ""}`;
        print(layer.handle.stack, prefix);
      }
    }
  };
  // @ts-ignore
  print((app as any)._router?.stack || []);
  res.json({ routes });
});

// Dev tester UI: simple page to explore routes and try POST actions
app.get("/tester", (_req, res) => {
  const html = `<!doctype html>
  <html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Habit Hero API Tester</title>
    <style>
      body { font-family: -apple-system, system-ui, Segoe UI, Roboto, sans-serif; margin: 24px; line-height: 1.4; }
      h1 { margin-bottom: 8px; }
      h2 { margin-top: 28px; margin-bottom: 8px; }
      .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 12px; }
      .card { border: 1px solid #ddd; border-radius: 8px; padding: 12px; }
      code { background: #f6f8fa; padding: 2px 6px; border-radius: 4px; }
      label { display: block; margin-top: 8px; font-size: 12px; color: #555; }
      input[type="text"], input[type="number"] { width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; }
      button { margin-top: 8px; padding: 8px 10px; border: 1px solid #222; background: #111; color: white; border-radius: 6px; cursor: pointer; }
      button.secondary { background: #fff; color: #111; }
      .muted { color: #666; font-size: 12px; }
      pre { background: #0b1021; color: #c8e1ff; padding: 12px; border-radius: 6px; overflow: auto; }
      .row { display: flex; gap: 8px; align-items: center; }
      .pill { display:inline-block; padding:2px 6px; border-radius:999px; font-size:12px; border:1px solid #ddd; }
    </style>
  </head>
  <body>
    <h1>Habit Hero API Tester</h1>
    <div class="muted">Quick links and simple forms to try endpoints in dev.</div>

    <h2>Quick Links (GET)</h2>
    <div class="grid">
      <div class="card"><div><span class="pill">GET</span> <code>/health</code></div><a href="/health" target="_blank">Open</a></div>
      <div class="card"><div><span class="pill">GET</span> <code>/me</code></div><a href="/me" target="_blank">Open</a></div>
      <div class="card"><div><span class="pill">GET</span> <code>/areas</code></div><a href="/areas" target="_blank">Open</a></div>
      <div class="card"><div><span class="pill">GET</span> <code>/habits</code></div><a href="/habits" target="_blank">Open</a></div>
      <div class="card"><div><span class="pill">GET</span> <code>/bad-habits</code></div><a href="/bad-habits" target="_blank">Open</a></div>
      <div class="card"><div><span class="pill">GET</span> <code>/store/controlled-bad-habits</code></div><a href="/store/controlled-bad-habits" target="_blank">Open</a></div>
      
    </div>

    <h2>POST Actions</h2>
    <div class="grid">
      <div class="card">
        <div><span class="pill">POST</span> <code>/actions/habits/:id/complete</code></div>
        <label>Habit ID</label>
        <input id="habitId" type="text" placeholder="habit id" />
        <button onclick="completeHabit()">Complete Habit</button>
      </div>

      <div class="card">
        <div><span class="pill">POST</span> <code>/actions/bad-habits/:id/record</code></div>
        <label>Bad Habit ID</label>
        <input id="badHabitId" type="text" placeholder="bad habit id" />
        <button onclick="recordBadHabit()">Record</button>
      </div>

      <div class="card">
        <div><span class="pill">POST</span> <code>/store/bad-habits/:id/buy</code></div>
        <label>Bad Habit ID</label>
        <input id="buyBadHabitId" type="text" placeholder="bad habit id" />
        <button onclick="buyBadHabit()">Buy Controlled Bad Habit</button>
      </div>
    </div>

    <h2>Create Data (POST)</h2>
    <div class="grid">
      <div class="card">
        <div><span class="pill">POST</span> <code>/areas</code></div>
        <label>Name</label>
        <input id="areaName" type="text" placeholder="e.g., Health" />
        <label>Icon</label>
        <input id="areaIcon" type="text" placeholder="e.g., 💪" />
        <label>xpPerLevel</label>
        <input id="areaXpPerLevel" type="number" value="100" />
        <label>levelCurve</label>
        <input id="areaLevelCurve" type="text" value="linear" placeholder="linear | exp" />
        <button onclick="createArea()">Create Area</button>
      </div>

      <div class="card">
        <div><span class="pill">POST</span> <code>/habits</code></div>
        <label>Area ID</label>
        <input id="habitAreaId" type="text" placeholder="area id" />
        <label>Name</label>
        <input id="habitName" type="text" placeholder="e.g., Read 10 pages" />
        <label>xpReward</label>
        <input id="habitXpReward" type="number" value="10" />
        <label>coinReward</label>
        <input id="habitCoinReward" type="number" value="5" />
        <label>cadence</label>
        <input id="habitCadence" type="text" placeholder="daily" />
        <div class="row"><input id="habitActive" type="checkbox" checked /> <label for="habitActive">isActive</label></div>
        <button onclick="createHabit()">Create Habit</button>
      </div>

      <div class="card">
        <div><span class="pill">POST</span> <code>/bad-habits</code></div>
        <label>Area ID (optional)</label>
        <input id="badAreaId" type="text" placeholder="area id or leave empty" />
        <label>Name</label>
        <input id="badName" type="text" placeholder="e.g., Junk food" />
        <label>lifePenalty</label>
        <input id="badLifePenalty" type="number" value="5" />
        <div class="row"><input id="badControllable" type="checkbox" /> <label for="badControllable">controllable</label></div>
        <label>coinCost</label>
        <input id="badCoinCost" type="number" value="0" />
        <div class="row"><input id="badActive" type="checkbox" checked /> <label for="badActive">isActive</label></div>
        <button onclick="createBadHabit()">Create Bad Habit</button>
      </div>
    </div>

    <h2>Response</h2>
    <pre id="out">(results will appear here)</pre>

    <script>
      const out = document.getElementById('out');
      function show(obj){ if(!out) return; out.textContent = typeof obj === 'string' ? obj : JSON.stringify(obj, null, 2); }
      async function postJson(url, body){
        const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) });
        const text = await res.text();
        try { show(JSON.parse(text)); } catch { show(text); }
      }
      async function completeHabit(){
        const el = document.getElementById('habitId');
        const id = el && 'value' in el ? String(el.value).trim() : '';
        if(!id) return show('Enter a habit id');
        await postJson('/actions/habits/' + encodeURIComponent(id) + '/complete', {});
      }
      async function recordBadHabit(){
        const el = document.getElementById('badHabitId');
        const id = el && 'value' in el ? String(el.value).trim() : '';
        if(!id) return show('Enter a bad habit id');
        await postJson('/actions/bad-habits/' + encodeURIComponent(id) + '/record', {});
      }
      async function buyBadHabit(){
        const el = document.getElementById('buyBadHabitId');
        const id = el && 'value' in el ? String(el.value).trim() : '';
        if(!id) return show('Enter a bad habit id');
        await postJson('/store/bad-habits/' + encodeURIComponent(id) + '/buy', {});
      }
      async function createArea(){
        const nameEl = document.getElementById('areaName');
        const iconEl = document.getElementById('areaIcon');
        const xpEl = document.getElementById('areaXpPerLevel');
        const curveEl = document.getElementById('areaLevelCurve');
        const body = {
          name: nameEl && 'value' in nameEl ? String(nameEl.value).trim() : '',
          icon: iconEl && 'value' in iconEl ? String(iconEl.value).trim() : undefined,
          xpPerLevel: xpEl && 'value' in xpEl ? Number(xpEl.value) : 100,
          levelCurve: curveEl && 'value' in curveEl ? String(curveEl.value).trim() : 'linear',
        };
        await postJson('/areas', body);
      }
      async function createHabit(){
        const areaEl = document.getElementById('habitAreaId');
        const nameEl = document.getElementById('habitName');
        const xpEl = document.getElementById('habitXpReward');
        const coinEl = document.getElementById('habitCoinReward');
        const cadEl = document.getElementById('habitCadence');
        const actEl = document.getElementById('habitActive');
        const body = {
          areaId: areaEl && 'value' in areaEl ? String(areaEl.value).trim() : '',
          name: nameEl && 'value' in nameEl ? String(nameEl.value).trim() : '',
          xpReward: xpEl && 'value' in xpEl ? Number(xpEl.value) : 10,
          coinReward: coinEl && 'value' in coinEl ? Number(coinEl.value) : 0,
          cadence: cadEl && 'value' in cadEl ? String(cadEl.value).trim() : undefined,
          isActive: !!(actEl && 'checked' in actEl ? actEl.checked : true),
        };
        await postJson('/habits', body);
      }
      async function createBadHabit(){
        const areaEl = document.getElementById('badAreaId');
        const nameEl = document.getElementById('badName');
        const penEl = document.getElementById('badLifePenalty');
        const ctrlEl = document.getElementById('badControllable');
        const costEl = document.getElementById('badCoinCost');
        const actEl = document.getElementById('badActive');
        const areaId = areaEl && 'value' in areaEl ? String(areaEl.value).trim() : '';
        const body = {
          areaId: areaId || undefined,
          name: nameEl && 'value' in nameEl ? String(nameEl.value).trim() : '',
          lifePenalty: penEl && 'value' in penEl ? Number(penEl.value) : 1,
          controllable: !!(ctrlEl && 'checked' in ctrlEl ? ctrlEl.checked : false),
          coinCost: costEl && 'value' in costEl ? Number(costEl.value) : 0,
          isActive: !!(actEl && 'checked' in actEl ? actEl.checked : true),
        };
        await postJson('/bad-habits', body);
      }
    </script>
  </body>
  </html>`;
  res.type("html").send(html);
});

// Only start the server when not under test
if (process.env.NODE_ENV !== "test") {
  const port = process.env.PORT || 4000;
  app.listen(port, () => {
    console.log(`API on :${port}`);
    // Auto-open Swagger UI in dev if possible
    if (process.env.NODE_ENV !== "production") {
      const url = `http://localhost:${port}/docs`;
      const platform = process.platform;
      const cmd =
        platform === "darwin"
          ? `open ${url}`
          : platform === "win32"
            ? `start ${url}`
            : `xdg-open ${url}`;
      exec(cmd, (err) => {
        if (err) console.log("(dev) Open Swagger UI manually:", url);
      });
    }
  });
}
