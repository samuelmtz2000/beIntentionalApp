# Habit Hero — iOS App (SwiftUI)

Native iOS client for Habit Hero, built with Swift 5.9+, SwiftUI, MVVM, async/await, and Combine. It connects to the local backend API for live data and actions (XP, coins, logs, etc.).

## Requirements

- Xcode 15 or newer
- iOS 17+ Simulator or device
- Backend running locally (recommended): `pnpm dev:api` from the repo root

## Features

- Tabs: Today, Habits, Stats, Settings
- Habits CRUD, quick completion (awards XP/coins)
- Global profile stats: life, coins, and global Level/XP derived from your activity
- Clear progress: Habits header shows “XP to next → {current} from {required}” with correct per‑level requirement (linear or exponential)
- User Config sheet (Config pill in Habits chip bar): edit XP per Level, Level curve (linear/exp), exponential multiplier, and XP computation mode (logs vs stored)
- Settings: editable API base URL

## Getting Started

1) Start the backend API (from repo root):
   - `pnpm db:migrate && pnpm db:seed`
   - `pnpm dev:api` (defaults to `http://localhost:4000`)
2) Open the project in Xcode: `apps/mobileIOS/mobileIOS.xcodeproj`
3) Choose an iOS 17+ simulator and Run (Product → Run)

## Configuration

- API base URL: open the app → Settings → set `API Base URL`.
  - Default: `http://localhost:4000`
  - Make sure the simulator can reach your machine’s localhost. For real devices, use your machine’s LAN IP.

## Project Structure

- `mobileIOS/` — Swift sources (SwiftUI views, view models, services)
- `mobileIOS.xcodeproj/` — Xcode project
- `mobileIOSTests/` — Unit tests
- `mobileIOSUITests/` — UI tests

Common modules:
- Networking layer (API service) using async/await to call the backend routes.
- Models aligned with the API (areas, habits, bad habits, logs, transactions).
- View models (MVVM) orchestrating API calls and local UI state.

## API Integration

The app targets the backend routes documented in the API docs and OpenAPI (Swagger):
- Profile: `GET /me`
- User config: `GET /users/:id/config`, `PUT /users/:id/config`
- Habits list: `GET /habits`
- Complete habit: `POST /actions/habits/:id/complete`
- Bad habits list: `GET /bad-habits`
- Record bad habit: `POST /actions/bad-habits/:id/record`
- Store endpoints as applicable

Ensure the backend is running and seeded so the app has demo data.

## UI Patterns

- Tab navigation: primary screens via bottom tabs.
- Pill navigation: horizontal chip bar for local sections (Player / Habits / Areas / Store) and a Config pill.
- Spotify‑like actions: leading full swipe = Record; trailing full swipe = Edit (full), Delete (with confirm).
- Forms: Good/Bad create & edit forms use Area pickers sourced from the Areas catalog. Bad can be “None (Global)”.

## Testing

- From Xcode: Product → Test (runs unit and UI test targets).
- Prefer testing view models and API service in isolation; stub network where useful.

## Troubleshooting

- White screen or empty data: verify the API is running and reachable from the simulator/device.
- 404/validation errors: confirm routes match the current backend version and input payloads.
- CORS not applicable for native iOS networking; connection issues are usually base URL or network reachability.
- Changing curve/multiplier while in “logs” mode recalculates past XP; if you want stable counters, switch to “stored” mode in the User Config sheet.
