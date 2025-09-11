---
name: design-review-ios
description: Complete a design review of the pending iOS UI changes on the current branch using Xcode Simulator MCP.
inputs:
  bundle_id: { description: "App bundle identifier" }
  app_path: { description: ".app or .ipa path to install" }
---

- Boot simulator(s) (iPhone 15, iPhone SE)
- Install and launch app
- Walk primary flows and capture screenshots
- Check accessibility tree for labels/traits/actions
- Toggle orientations and Dynamic Type
- Export review as Markdown with findings and evidence

