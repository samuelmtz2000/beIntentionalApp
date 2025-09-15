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
