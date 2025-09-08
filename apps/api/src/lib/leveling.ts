export function xpForLevel(
  level: number,
  xpPerLevel: number,
  curve: "linear" | "exp" = "linear",
  multiplier = 1.5
): number {
  if (curve === "linear") return xpPerLevel;
  // exponential: requirement scales by multiplier^(level-1)
  return Math.max(1, Math.floor(xpPerLevel * Math.pow(Math.max(1, multiplier), Math.max(0, level - 1))));
}

export function applyHabitCompletion(
  currentXP: number,
  currentLevel: number,
  addXP: number,
  xpPerLevel: number,
  curve: "linear" | "exp" = "linear"
): { level: number; xp: number } {
  let xp = currentXP + addXP;
  let level = currentLevel;
  while (xp >= xpForLevel(level, xpPerLevel, curve)) {
    xp -= xpForLevel(level, xpPerLevel, curve);
    level += 1;
  }
  return { level, xp };
}

export function computeLevelFromTotalXP(
  totalXP: number,
  xpPerLevel: number,
  curve: "linear" | "exp" = "linear",
  multiplier = 1.5
): { level: number; xp: number } {
  let remaining = Math.max(0, totalXP);
  let level = 1;
  while (true) {
    const need = xpForLevel(level, xpPerLevel, curve, multiplier);
    if (remaining < need) return { level, xp: remaining };
    remaining -= need;
    level += 1;
  }
}
