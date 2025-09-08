---
title: Welcome to Habit Hero
---

This monorepo hosts the Habit Hero backend API and the native iOS client. Use this site for API docs; see the iOS app README in the repo for frontend details.

What’s inside
- API (apps/api): Express + TypeScript + Prisma (SQLite)
  - Dev server: `pnpm dev:api` (on `http://localhost:4000`)
  - Swagger UI: `http://localhost:4000/docs`
  - Dev tester: `http://localhost:4000/tester`
- iOS App (apps/mobileIOS): SwiftUI + MVVM
  - Open `apps/mobileIOS/mobileIOS.xcodeproj` in Xcode 15+
  - Set API base URL in app Settings (default `http://localhost:4000`)

Getting started
1. From repo root: `pnpm db:migrate && pnpm db:seed`
2. Start API: `pnpm dev:api`
3. iOS app: open the Xcode project and Run on an iOS 17+ simulator

Next steps
- Continue to the API Overview for endpoints and models.
- For the iOS app, read `apps/mobileIOS/README.md` in the repository.
