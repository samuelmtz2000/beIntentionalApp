import { Router } from "express";
import areas from "./areas";
import habits from "./habits";
import badHabits from "./badHabits";
import actions from "./actions";
import store from "./store";
import me from "./me";

const api = Router();
api.get("/__ping", (_req, res) => res.json({ ok: true }));
api.use("/areas", areas);
api.use("/habits", habits);
api.use("/bad-habits", badHabits);
api.use("/actions", actions);
api.use("/store", store);
api.use("/me", me);

export default api;
