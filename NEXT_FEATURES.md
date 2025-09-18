# Next Plant Features

A running list of upcoming features/tasks to track and prioritize.

1. Change deletions to logical deletes (soft delete) across the system to retain history/audit instead of physically removing rows.
2. Refactor Swift code to a more modular architecture (smaller files/components, clear boundaries, reusable sheets/services):
   Refactor the current SwiftUI app into a **feature-first, modular architecture** with small reusable files and a shared Design System. Keep functionality equivalent. Target iOS 17+ (SwiftData) or fall back to protocols so storage can be swapped later.

- Config is a proper pill with the same style and triggers the config sheet when tapped. - Layout spacing adjusted to reduce cramped feel.
  - Habits section headers
    - Styled headers with icons:
      - “Good Habits” with checkmark.seal.fill
      - “Bad Habits” with exclamationmark.triangle.fill
    - Better spacing and typography (dsFont(.headerMD)).
  - Store, Archive, Areas pills
    - All pills across the nav (including Store and Archive) are consistent in style and include icons.
  - Archive and Areas panels
    - Rows use Design System cardStyle + dsFont typography for titles and secondary text.
    - listRowBackground cleared so cards read properly.

## Goals

- Split large views into **feature folders** with colocated View + ViewModel + Components.
- Extract shared UI into a **DesignSystem** (colors, spacing, typography, reusable subviews, ViewModifiers, ButtonStyles).
- Keep business logic out of views (MVVM). Views bind to observable state.
- Prepare for scalability via **Swift Package Manager** (local packages) for `DesignSystem` and `Core` (models/services).
- Maintain/offline storage (SwiftData) behind a protocol so we can swap to GRDB/Realm if needed.

3. Unify form layouts so all screens share the same pattern — Cancel and Save buttons at the top (navigation bar) for consistency and better aesthetics.
4. Remove the first page/tab called "Today" (it will not be used).
5. Game configurations for when Health reaches zero and for starting/restoring the game (details to be determined later).
6. Streak configuration: add a global streak and per‑habit streaks; track missed days ("not registered" streak) as part of the model.
7. add emojis to habits
8. Create a area view page where you can see the good and bad habits per area and the log and a general view fow the same grouping per area.
9. create MPC server and an UI chat to do all the actions from the backend.
10. configure good habits to have general frequency configurations (like google tasks have, daily weekly monthly, per day of the week with selection of the days etc)
11. create table configurations to be able to filter and group habits, areas, bad habits
12. Production hardening for the first release (stability, performance, error handling, analytics, QA checklist, and release notes).
   - HealthKit (prod readiness)
     - Capabilities & signing
       - Add HealthKit capability for Debug/Release; ensure CODE_SIGN_ENTITLEMENTS is set and provisioning profiles include `com.apple.developer.healthkit`.
       - Request read-only access (no write). Limit to `distanceWalkingRunning` and `workout` types.
     - Privacy & App Store
       - Localize `NSHealthShareUsageDescription` (avoid “marathon” wording; use “running challenge”).
       - Complete App Store privacy questionnaires and provide a privacy policy explaining Health data usage.
       - Add App Review notes describing the feature and data handling.
     - UX & consent
       - Add pre-permission education screen. Handle `notDetermined`, `denied/restricted` with clear guidance and deep link to Settings.
       - Do not block broader app usage when Health access is denied; only gate Running Challenge.
     - Data pipeline & correctness
       - Switch distance updates to `HKObserverQuery` + `HKAnchoredObjectQuery` with stored anchors for background updates; de-duplicate samples.
       - Clamp cumulative distance; enforce monotonic increases; handle backfilled workouts and timezone/DST shifts.
       - Standardize units (meters internally; format km/mi by locale). Define rounding/display rules.
       - Anti-cheat: add server validations (max km/day, reasonable pace checks, exclude manual entries optionally).
     - Background behavior
       - Evaluate BGTask scheduling to refresh progress when observers fire; throttle frequency and power usage.
     - Error handling & resiliency
       - Add retry/backoff for network sync; queue offline progress; ensure idempotent PUTs for recovery-progress.
       - Surface recoverable errors with toasts; log non-fatal errors (disable verbose logs in release).
     - QA & testing
       - Test on real devices (simulator Health data is limited). Seed workouts; verify denied/restricted flows.
       - Cover time changes, DST, locale changes, airplane mode/offline, low power mode.
       - Add unit tests for distance windowing and completion detection (mock HK layer behind protocol).
     - Analytics & monitoring
       - Track Health permission funnel, recoveries started/completed, average completion time/distance.
       - Add crash/ANR monitoring for the feature flow.
     - Security & storage
       - Store only minimal progress state locally (no raw Health samples). Secure tokens/secrets; ensure TLS.
     - Internationalization
       - Localize copy; use NumberFormatter/MeasurementFormatter; support right-to-left if needed.
     - Documentation & runbooks
       - Document troubleshooting steps for HealthKit (no data, denied, restricted, background). Provide on-call runbook.

Sprint 2

1. Change exp and coin configuration instead of configuring a specific xp and coines gained by good habit, make parameters: level of will needed, time consumed in habit, etc. do a creative process and psicological effects to configure this. Same with bad habits to determine the price and life lost.
2. Prepare app to work with login using google and storing data separated for each user/player.
3. Prepare for multiplayer gaming
4. Create an avatar/mascot and iterations of how good habits make good things to the avatar (weapons health cleaning) and how bad habits do the contrary

Sprint 2

1. Change exp and coin configuration instead of configuring a specific xp and coines gained by good habit, make parameters: level of will needed, time consumed in habit, etc. do a creative process and psicological effects to configure this. Same with bad habits to determine the price and life lost.
2. Prepare app to work with login using google and storing data separated for each user/player.
3. Prepare for multiplayer gaming
4. Create an avatar/mascot and iterations of how good habits make good things to the avatar (weapons health cleaning) and how bad habits do the contrary

> Note: This document is a living list; we’ll refine scope and ordering as we move forward.
