export function xpForLevel(level: number, xpPerLevel: number, curve: "linear" | "exp" = "linear"): number {
  if (curve === "linear") return xpPerLevel;
  // simple exponential: requirement scales with current level
  return Math.max(1, Math.floor(xpPerLevel * level));
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

