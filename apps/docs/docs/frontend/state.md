---
title: State & Persistence
---

State lives in view models and derives from backend truth. Persist only user preferences and ephemeral UI when helpful.

Patterns
- `@Observable` view models, `@Published` where Combine is used
- Derived state helpers; avoid duplicating source of truth
- Cache small responses in memory; invalidate on actions

Preferences
- Store non‑sensitive prefs (e.g., base URL) in `UserDefaults`

```swift
enum Preferences {
    @AppStorage("apiBaseURL") static var apiBaseURL: String = "http://localhost:4000"
}
```

Offline
- Graceful error UI; retry buttons
- Consider lightweight request queueing for actions if needed later

