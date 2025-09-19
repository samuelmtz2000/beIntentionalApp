# Banners — DSInfoBanner

Purpose
- Provide a consistent inline banner within the header for status messaging and actions, e.g., Game Over and Recovery Complete.

Component
- `DSInfoBanner(icon:title:message:actionTitle:action:)`
- Layout: leading SF Symbol icon, title (headerMD), subtitle (caption), trailing button (`DSButton .secondary`).
- Container: rounded 16pt card using `surfaceCard`.

Usage
- Render inside `NavigationHeaderContainer` below `PlayerHeader` and above `MainNavigationBar` so banners appear across views.
- Game Over example:
```
DSInfoBanner(
  icon: "figure.run.circle.fill",
  title: "Game Over",
  message: "Bad habits are disabled until you complete recovery.",
  actionTitle: "Details",
  action: onOpenRecovery
)
```
- Recovery Complete example:
```
DSInfoBanner(
  icon: "figure.run.circle.fill",
  title: "Recovery Complete",
  message: "You reached the running challenge distance. Finalize to restore the game.",
  actionTitle: "Details",
  action: onOpenRecovery
)
```

Behavior
- Banners are controlled by `NavigationHeaderContainer` using `GameStateManager` and `ProfileViewModel`:
  - Game Over when `(profile.life <= 0) || (game.state == .gameOver)`.
  - Recovery Complete when `game.state == .recovery && game.recoveryDistance >= game.recoveryTarget`.

Notes
- Keep copy concise; avoid truncation by allowing subtitle to wrap.
- Prefer SF Symbols for icons; use emoji only for exceptional cases where symbols don’t render.

