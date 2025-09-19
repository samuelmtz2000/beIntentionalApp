import "dotenv/config";
import express from "express";
import helmet from "helmet";
import cors from "cors";
import rateLimit from "express-rate-limit";
import type { RequestHandler } from "express";
import api from "./router/index.js";
import areas from "./router/areas.js";
import { exec } from "node:child_process";
import { createRequire } from "node:module";
import spec from "./openapi.js";
import { createRequire as createReq2 } from "node:module";
const req2 = createReq2(import.meta.url);
try {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const resolved = req2.resolve("@prisma/client");
  console.log("Using Prisma client from:", resolved);
} catch {}

export const app = express();
app.use(express.json());
app.use(helmet());
app.use(cors());
const limiter = rateLimit({ windowMs: 60_000, max: 120 }) as unknown as RequestHandler;
app.use(limiter);

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

// Dev-only: allow clean shutdown to avoid orphaned processes during automation
app.get("/__shutdown", (_req, res) => {
  res.json({ ok: true, shuttingDown: true });
  setTimeout(() => process.exit(0), 50);
});

// (Dev tester UI removed. Use Swagger at /docs)
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
