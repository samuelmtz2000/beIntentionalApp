---
title: Troubleshooting
---

Common Issues
- Blank data: ensure API is running and reachable from the simulator
- 404/422 errors: verify endpoint paths and payloads match backend version
- Network on device: use your machine’s LAN IP instead of localhost

Debugging Tips
- Inspect requests in Xcode’s Network debugger
- Log errors in debug builds; prefer user‑friendly messages in release
- Add accessibility identifiers for stable UI tests

Performance
- Use Instruments to profile rendering and allocations
- Avoid heavy work on the main thread; offload to background tasks

