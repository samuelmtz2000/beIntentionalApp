# Habit Hero — iOS App (SwiftUI)

Native iOS client for Habit Hero, built with Swift 5.9+, SwiftUI, MVVM, async/await, and Combine. It connects to the local backend API for live data and actions (XP, coins, logs, etc.).

## Requirements

- Xcode 15 or newer
- iOS 17+ Simulator or device
- Backend running locally (recommended): `pnpm dev:api` from the repo root

## Features

- **Core Navigation**: Streamlined 2-tab interface (Habits, Settings) with pill-based sub-navigation
- **Habit Management**: Complete CRUD operations for good and bad habits with swipe actions
- **Real-time Feedback**: Toast notifications for habit completions showing XP/coin rewards and life penalties
- **Player Stats**: Global profile with life, coins, and level progression with XP tracking
- **Multi-Area Support**: Organize habits by areas with individual level curves and multipliers
- **Store System**: Purchase controllable bad habits with coins in a card-based interface
- **Archive & Restore**: Soft-delete system for habits and areas with restoration capabilities
- **Theme Support**: System/Light/Dark mode switching with consistent design system
- **User Configuration**: Customizable XP curves, level multipliers, and appearance settings
- **API Integration**: Full backend synchronization with offline-friendly error handling

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

- **Tab Navigation**: Streamlined 2-tab interface (Habits, Settings) for primary app sections
- **Pill Navigation**: Horizontal scrolling chips for sub-sections (Player, Habits, Areas, Store, Archive, Config)
- **Swipe Actions**: Leading swipe → Record habit; trailing swipe → Edit/Delete (with confirmation)
- **Toast Notifications**: Top-sliding feedback messages for habit completions with auto-dismiss
  - Success toasts (green): "✅ [Habit] completed! +[XP] XP, +[coins] coins"
  - Warning toasts (red): "⚠️ [Habit] recorded. -[penalty] life"
- **Card-based Lists**: All content uses Design System cards with consistent shadows and typography
- **Store Interface**: Two-column card grid with Buy buttons and coin cost display
- **Forms**: Good/Bad habit creation with Area pickers; Bad habits can be "None (Global)"
- **Progressive Disclosure**: Player stats and area details expand with context-appropriate information

## Design System

- **Design Tokens**: Semantic colors, spacing, radii, typography scales with `dsFont()` wrapper
- **Component Library**: Button styles (Primary/Secondary), card modifier, toast notifications
- **Toast System**: 
  - `ToastMessage` model with type-safe messaging
  - `ToastType` enum (success, error, info) with appropriate icons and colors
  - `.toast()` view modifier for easy integration
  - Auto-dismiss with smooth animations (slide from top)
- **Theme Support**: System/Light/Dark mode with consistent color schemes applied app-wide
- **Accessibility**: Descriptive labels, 44×44pt touch targets, dynamic type support, semantic colors

## Testing

- From Xcode: Product → Test (runs unit and UI test targets).
- Prefer testing view models and API service in isolation; stub network where useful.

## Troubleshooting

- White screen or empty data: verify the API is running and reachable from the simulator/device.
- 404/validation errors: confirm routes match the current backend version and input payloads.
- CORS not applicable for native iOS networking; connection issues are usually base URL or network reachability.
- Changing curve/multiplier while in “logs” mode recalculates past XP; if you want stable counters, switch to “stored” mode in the User Config sheet.
