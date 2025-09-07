---
title: Build & Release
---

Local Builds
- Open `apps/mobileIOS/mobileIOS.xcodeproj` in Xcode 15+
- Select scheme `mobileIOS` → Build/Run on iOS 17+ simulator

Signing
- Use your Apple Developer Team for automatic signing
- Set bundle identifier per environment

Environments
- Base URL controlled via in‑app Settings (UserDefaults)
- Optionally add build configs (Debug/Staging/Release) with defaults

App Store
- Archive from Xcode (Any iOS Device) → Distribute to TestFlight/App Store

CI (optional)
- Use `xcodebuild` for headless build/test
- Cache derived data to speed up builds

