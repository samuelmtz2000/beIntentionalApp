# HabitHero (iOS)

Native SwiftUI iOS client for Habit Hero. Uses Swift 5.9+, SwiftUI, MVVM, async/await, Combine.

- Tabs: Today, Habits, Stats, Settings
- API: connects to the local backend at `http://localhost:4000` (configurable in Settings)
- Features: Habits CRUD, quick completion (awards XP/coins), profile stats

## Run

1) Open Xcode and select the project in `apps/mobileIOS/mobileIOS.xcodeproj`
2) Select a simulator (iOS 17+) and Run

Or from Xcode: Product → Run

## Configure API base URL

In the Settings tab, set the `API Base URL` (default `http://localhost:4000`).

## Tests

Targets include unit tests. From Xcode, run Product → Test.

## Notes

- The client mirrors the backend API routes documented at `apps/api/README.md`.
- Quick actions use `POST /actions/habits/:id/complete` to create logs, update area levels, and coin balance.
