import prisma from "./prisma";

const DEFAULT_USER_ID = "seed-user-1";

export type GeneralDay = {
  date: string; // YYYY-MM-DD
  completedGood: number;
  totalActiveGood: number;
  hasUnforgivenBad: boolean;
  unforgivenBadCount: number;
  totalBadCount: number;
  daySuccess: boolean | null; // null = freeze day (no active good & no unforgiven bad)
};

export type GeneralStreak = {
  currentCount: number;
  longestCount: number;
  days: GeneralDay[];
};

function toDate(dateStr: string): Date {
  // Interpret as local date at 00:00
  const [y, m, d] = dateStr.split("-").map((s) => Number(s));
  return new Date(y, (m ?? 1) - 1, d ?? 1, 0, 0, 0, 0);
}

function fmtDateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function addDays(d: Date, n: number): Date {
  const copy = new Date(d.getTime());
  copy.setDate(copy.getDate() + n);
  return copy;
}

function rangeDays(fromKey: string, toKey: string): string[] {
  const from = toDate(fromKey);
  const to = toDate(toKey);
  const days: string[] = [];
  for (let d = new Date(from); d <= to; d = addDays(d, 1)) {
    days.push(fmtDateKey(d));
  }
  return days;
}

export async function computeGeneralStreak(params: {
  userId?: string;
  from: string; // YYYY-MM-DD inclusive
  to: string; // YYYY-MM-DD inclusive
}): Promise<GeneralStreak> {
  const userId = params.userId ?? DEFAULT_USER_ID;
  const days = rangeDays(params.from, params.to);

  // Denominator: active good habits (current state)
  const totalActiveGood = await prisma.goodHabit.count({ where: { isActive: true, deletedAt: null } });

  // Window timestamps
  const start = toDate(days[0]);
  const end = addDays(toDate(days[days.length - 1]), 1); // exclusive upper bound

  // Fetch logs within window
  const [habitLogs, badLogs] = await Promise.all([
    prisma.habitLog.findMany({
      where: { userId, timestamp: { gte: start, lt: end } },
      select: { habitId: true, timestamp: true },
    }),
    prisma.badHabitLog.findMany({
      where: { userId, timestamp: { gte: start, lt: end } },
      select: { avoidedPenalty: true, timestamp: true },
    }),
  ]);

  // Map day -> set of completed habit ids
  const completedPerDay = new Map<string, Set<string>>();
  for (const log of habitLogs) {
    const key = fmtDateKey(new Date(log.timestamp));
    if (!completedPerDay.has(key)) completedPerDay.set(key, new Set());
    completedPerDay.get(key)!.add(log.habitId);
  }

  // Map day -> unforgiven bad count
  const unforgivenCountPerDay = new Map<string, number>();
  for (const b of badLogs) {
    const key = fmtDateKey(new Date(b.timestamp));
    if (!unforgivenCountPerDay.has(key)) unforgivenCountPerDay.set(key, 0);
    if (!b.avoidedPenalty) {
      unforgivenCountPerDay.set(key, (unforgivenCountPerDay.get(key) ?? 0) + 1);
    }
  }
  // Map day -> total bad occurrences (forgiven + unforgiven)
  const totalBadPerDay = new Map<string, number>();
  for (const b of badLogs) {
    const key = fmtDateKey(new Date(b.timestamp));
    totalBadPerDay.set(key, (totalBadPerDay.get(key) ?? 0) + 1);
  }

  const results: GeneralDay[] = days.map((date) => {
    const completedGood = completedPerDay.get(date)?.size ?? 0;
    const unforgivenBadCount = unforgivenCountPerDay.get(date) ?? 0;
    const totalBadCount = totalBadPerDay.get(date) ?? 0;
    const hasUnforgivenBad = unforgivenBadCount > 0;
    let daySuccess: boolean | null;
    if (totalActiveGood === 0) {
      daySuccess = hasUnforgivenBad ? false : null; // reset if unforgiven, else freeze
    } else {
      const pct = Math.floor((completedGood / totalActiveGood) * 100);
      daySuccess = pct >= 80 && !hasUnforgivenBad;
    }
    return { date, completedGood, totalActiveGood, hasUnforgivenBad, unforgivenBadCount, totalBadCount, daySuccess };
  });

  // Compute streaks from ordered days
  let longest = 0;
  let current = 0;
  for (const r of results) {
    if (r.daySuccess === true) {
      current += 1;
      if (current > longest) longest = current;
    } else if (r.daySuccess === false) {
      current = 0;
    } // null (freeze) leaves current as-is
  }

  return { currentCount: current, longestCount: longest, days: results };
}

export type HabitStreak = {
  habitId: string;
  type: "good" | "bad";
  currentCount: number;
  longestCount: number;
};

export async function computePerHabitStreaks(params: {
  userId?: string;
  from: string;
  to: string;
}): Promise<HabitStreak[]> {
  const userId = params.userId ?? DEFAULT_USER_ID;
  const days = rangeDays(params.from, params.to);
  const start = toDate(days[0]);
  const end = addDays(toDate(days[days.length - 1]), 1);

  const [goodHabits, badHabits, habitLogs, badLogs] = await Promise.all([
    prisma.goodHabit.findMany({ where: { isActive: true, deletedAt: null }, select: { id: true } }),
    prisma.badHabit.findMany({ where: { isActive: true, deletedAt: null }, select: { id: true } }),
    prisma.habitLog.findMany({ where: { userId, timestamp: { gte: start, lt: end } }, select: { habitId: true, timestamp: true } }),
    prisma.badHabitLog.findMany({ where: { userId, timestamp: { gte: start, lt: end } }, select: { badHabitId: true, avoidedPenalty: true, timestamp: true } }),
  ]);

  // Map per day sets for quick lookup
  const goodDayMap = new Map<string, Map<string, boolean>>(); // date -> habitId -> done
  for (const l of habitLogs) {
    const key = fmtDateKey(new Date(l.timestamp));
    if (!goodDayMap.has(key)) goodDayMap.set(key, new Map());
    goodDayMap.get(key)!.set(l.habitId, true);
  }

  const badDayMap = new Map<string, Map<string, { unforgiven: boolean; forgiven: boolean }>>();
  for (const l of badLogs) {
    const key = fmtDateKey(new Date(l.timestamp));
    if (!badDayMap.has(key)) badDayMap.set(key, new Map());
    const byHabit = badDayMap.get(key)!;
    const cur = byHabit.get(l.badHabitId) || { unforgiven: false, forgiven: false };
    if (l.avoidedPenalty) cur.forgiven = true; else cur.unforgiven = true;
    byHabit.set(l.badHabitId, cur);
  }

  const res: HabitStreak[] = [];

  // Good: streak of consecutive done days; miss resets; all days considered eligible
  for (const h of goodHabits) {
    let cur = 0;
    let longest = 0;
    for (const day of days) {
      const done = goodDayMap.get(day)?.get(h.id) ?? false;
      if (done) {
        cur += 1;
        if (cur > longest) longest = cur;
      } else {
        cur = 0;
      }
    }
    res.push({ habitId: h.id, type: "good", currentCount: cur, longestCount: longest });
  }

  // Bad: clean streak — day increments if no unforgiven; unforgiven resets
  for (const b of badHabits) {
    let cur = 0;
    let longest = 0;
    for (const day of days) {
      const mark = badDayMap.get(day)?.get(b.id) || { unforgiven: false, forgiven: false };
      if (mark.unforgiven) {
        cur = 0;
      } else {
        cur += 1; // forgiven or no logs both count as clean
        if (cur > longest) longest = cur;
      }
    }
    res.push({ habitId: b.id, type: "bad", currentCount: cur, longestCount: longest });
  }

  return res;
}

export async function computeHabitHistory(params: {
  userId?: string;
  habitId: string;
  type: "good" | "bad";
  from: string;
  to: string;
}): Promise<{ date: string; status: string }[]> {
  const userId = params.userId ?? DEFAULT_USER_ID;
  const days = rangeDays(params.from, params.to);
  const start = toDate(days[0]);
  const end = addDays(toDate(days[days.length - 1]), 1);

  if (params.type === "good") {
    const habit = await prisma.goodHabit.findFirst({ where: { id: params.habitId, deletedAt: null }, select: { isActive: true } });
    const logs = await prisma.habitLog.findMany({ where: { userId, habitId: params.habitId, timestamp: { gte: start, lt: end } }, select: { timestamp: true } });
    const daySet = new Set<string>(logs.map((l) => fmtDateKey(new Date(l.timestamp))));
    const active = !!habit?.isActive;
    return days.map((d) => ({ date: d, status: active ? (daySet.has(d) ? "done" : "miss") : "inactive" }));
  }

  // bad
  const logs = await prisma.badHabitLog.findMany({ where: { userId, badHabitId: params.habitId, timestamp: { gte: start, lt: end } }, select: { avoidedPenalty: true, timestamp: true } });
  const byDay = new Map<string, { unforgiven: boolean; forgiven: boolean }>();
  for (const l of logs) {
    const key = fmtDateKey(new Date(l.timestamp));
    const cur = byDay.get(key) || { unforgiven: false, forgiven: false };
    if (l.avoidedPenalty) cur.forgiven = true; else cur.unforgiven = true;
    byDay.set(key, cur);
  }
  return days.map((d) => {
    const mark = byDay.get(d) || { unforgiven: false, forgiven: false };
    if (mark.unforgiven) return { date: d, status: "occurred" };
    if (mark.forgiven) return { date: d, status: "forgiven" };
    return { date: d, status: "clean" };
  });
}
