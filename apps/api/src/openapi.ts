// Minimal OpenAPI spec to power Swagger UI testing
// Note: keep in sync with routes over time.
const spec = {
  openapi: "3.0.3",
  info: {
    title: "Habit Hero API",
    version: "1.0.0",
    description: "Interactive tester for Habit Hero endpoints",
  },
  servers: [{ url: "http://localhost:4000" }],
  paths: {
    "/health": {
      get: { summary: "Health check", responses: { "200": { description: "OK" } } },
    },
    "/me": {
      get: { summary: "Profile snapshot", responses: { "200": { description: "Profile (includes ownedBadHabits)" } } },
    },
    "/areas": {
      get: { summary: "List areas", responses: { "200": { description: "Areas" } } },
      post: {
        summary: "Create area",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  icon: { type: "string" },
                  xpPerLevel: { type: "integer", minimum: 10 },
                  levelCurve: { type: "string", enum: ["linear", "exp"] },
                },
                required: ["name", "xpPerLevel", "levelCurve"],
              },
            },
          },
        },
        responses: { "201": { description: "Created" } },
      },
    },
    "/areas/{id}": {
      put: {
        summary: "Update area (partial)",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  icon: { type: "string" },
                  xpPerLevel: { type: "integer", minimum: 10 },
                  levelCurve: { type: "string", enum: ["linear", "exp"] },
                },
              },
            },
          },
        },
        responses: { "200": { description: "Updated" }, "404": { description: "Not found" } },
      },
      delete: {
        summary: "Delete area",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "204": { description: "Deleted" }, "404": { description: "Not found" } },
      },
    },
    "/habits": {
      get: { summary: "List good habits", responses: { "200": { description: "Habits" } } },
      post: {
        summary: "Create good habit",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  areaId: { type: "string" },
                  name: { type: "string" },
                  xpReward: { type: "integer", minimum: 1 },
                  coinReward: { type: "integer", minimum: 0 },
                  cadence: { type: "string" },
                  isActive: { type: "boolean" },
                },
                required: ["areaId", "name", "xpReward", "coinReward"],
              },
            },
          },
        },
        responses: { "201": { description: "Created" } },
      },
    },
    "/habits/{id}": {
      put: {
        summary: "Update good habit (partial)",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  areaId: { type: "string" },
                  name: { type: "string" },
                  xpReward: { type: "integer", minimum: 1 },
                  coinReward: { type: "integer", minimum: 0 },
                  cadence: { type: "string" },
                  isActive: { type: "boolean" },
                },
              },
            },
          },
        },
        responses: { "200": { description: "Updated" }, "404": { description: "Not found" } },
      },
      delete: {
        summary: "Delete good habit",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "204": { description: "Deleted" }, "404": { description: "Not found" } },
      },
    },
    "/bad-habits": {
      get: { summary: "List bad habits", responses: { "200": { description: "Bad habits" } } },
      post: {
        summary: "Create bad habit",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  areaId: { type: "string" },
                  name: { type: "string" },
                  lifePenalty: { type: "integer", minimum: 1 },
                  controllable: { type: "boolean" },
                  coinCost: { type: "integer", minimum: 0 },
                  isActive: { type: "boolean" },
                },
                required: ["name", "lifePenalty", "controllable", "coinCost"],
              },
            },
          },
        },
        responses: { "201": { description: "Created" } },
      },
    },
    "/bad-habits/{id}": {
      put: {
        summary: "Update bad habit (partial)",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  areaId: { type: "string" },
                  name: { type: "string" },
                  lifePenalty: { type: "integer", minimum: 1 },
                  controllable: { type: "boolean" },
                  coinCost: { type: "integer", minimum: 0 },
                  isActive: { type: "boolean" },
                },
              },
            },
          },
        },
        responses: { "200": { description: "Updated" }, "404": { description: "Not found" } },
      },
      delete: {
        summary: "Delete bad habit",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "204": { description: "Deleted" }, "404": { description: "Not found" } },
      },
    },
    "/actions/habits/{id}/complete": {
      post: {
        summary: "Complete habit",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Updated area + coins" }, "404": { description: "Not found" } },
      },
    },
    "/actions/bad-habits/{id}/record": {
      post: {
        summary: "Record bad habit (checks ownership of controllable habits to avoid penalty)",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Life updated (or avoided penalty)" }, "404": { description: "Not found" } },
      },
    },
    "/store/controlled-bad-habits": { get: { summary: "List purchasable (controllable) bad habits (uses coinCost as price)", responses: { "200": { description: "OK" } } } },
    "/store/bad-habits/{id}/buy": {
      post: {
        summary: "Buy a controlled bad habit (one-time purchase)",
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
        responses: { "200": { description: "Purchased" }, "400": { description: "Invalid or insufficient coins" }, "409": { description: "Already purchased" } },
      },
    },
  },
};

export default spec as any;
