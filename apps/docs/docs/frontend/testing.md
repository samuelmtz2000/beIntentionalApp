---
title: Testing
---

Goals: fast, reliable feedback; test behavior, not implementation details.

Unit Tests
- Test view models with stubbed services
- Validate mapping, error handling, and state transitions

```swift
import XCTest
@testable import mobileIOS

final class HabitsViewModelTests: XCTestCase {
    func testLoadSuccess() async throws {
        let stub = HabitsServiceStub(result: .success([.init(id: "1", areaId: "a", name: "Read", xpReward: 5, coinReward: 1, isActive: true)]))
        let vm = await HabitsViewModel(habitsService: stub)
        await vm.load()
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertNil(vm.error)
    }
}
```

UI Tests
- Focus on critical flows (complete habit, record bad habit)
- Prefer accessibility identifiers for robust selection

Guidelines
- Isolate side effects; prefer protocol‑driven injection for services
- Avoid sleeps; use expectations for async work

