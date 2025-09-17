# Marathon Recovery Feature - Development Roadmap

## 🎯 Project Overview

**Feature**: Game Over & Marathon Recovery System  
**Duration**: 4 weeks  
**Team**: iOS Developer, Backend Developer, QA  
**Priority**: High (Point 5 in NEXT_FEATURES.md)

**Current Status**: Backend foundation complete; PR open (feature/marathon-recovery-backend → feature/game-over-config).  
PR: https://github.com/samuelmtz2000/beIntentionalApp/pull/25

## 📋 Pre-Development Checklist

- [ ] Review Apple HealthKit documentation
- [ ] Set up Apple Developer account for HealthKit capability
- [x] Design database schema changes
- [x] Create UI/UX mockups
- [x] Define acceptance criteria
- [ ] Set up test devices with Health app

## 🚀 Week 1: Foundation & Setup

### Day 1-2: HealthKit Research & Setup

- [ ] Study HealthKit framework documentation
- [ ] Add HealthKit capability to Xcode project
- [ ] Configure Info.plist with usage descriptions
- [ ] Create basic HealthKit permission request flow
- [ ] Test permission grants on simulator and device

### Day 3-4: Backend Infrastructure

- [x] Update user model with game state fields
- [x] Create migration for database schema changes
- [x] Implement game state API endpoints
- [x] Add recovery tracking fields
- [x] Write API documentation

### Day 5: Integration Planning

- [ ] Create HealthKitService class structure
- [ ] Design RecoveryViewModel architecture
- [ ] Plan state management approach
- [ ] Set up development environment
- [ ] Create feature branch

## 🏗️ Week 2: Core Implementation

### Day 1-2: Game State Management

```swift
// Implementation tasks
- [ ] Create GameState enum
- [ ] Add game state to Profile model
- [ ] Implement state persistence
- [ ] Create state transition logic
- [ ] Add state change notifications
```

### Day 3-4: Game Over Detection

```swift
// Implementation tasks
- [ ] Monitor health in BadHabitsViewModel
- [ ] Trigger game over when health <= 0
- [ ] Create GameOverView SwiftUI component
- [ ] Implement modal presentation
- [ ] Disable habit actions during game over (backend guard)
```

### Day 5: HealthKit Integration

```swift
// Implementation tasks
- [ ] Implement HealthKitService
- [ ] Add authorization request
- [ ] Create distance query methods
- [ ] Test data retrieval
- [ ] Handle authorization states
```

## 🎮 Week 3: Recovery System

### Day 1-2: Recovery UI

```swift
// UI Components
- [ ] MarathonRecoveryView
- [ ] ProgressBar component
- [ ] Distance display
- [ ] Milestone indicators
- [ ] Daily stats view
```

### Day 3-4: Progress Tracking

```swift
// Implementation tasks
- [ ] Query HealthKit data periodically
- [ ] Calculate cumulative distance
- [ ] Update progress in real-time
- [ ] Sync with backend
- [ ] Store local progress cache
```

### Day 5: Completion Logic

```swift
// Implementation tasks
- [ ] Detect 42km completion
- [ ] Trigger celebration screen
- [ ] Restore health to 1000
- [ ] Reset game state
- [ ] Clear recovery data
```

## ✨ Week 4: Polish & Testing

### Day 1-2: Visual Polish

- [ ] Add animations for progress updates
- [ ] Implement milestone celebrations
- [ ] Create completion animation
- [ ] Add haptic feedback
- [ ] Optimize UI performance

### Day 3-4: Edge Cases & Error Handling

- [ ] Handle HealthKit permission denial
- [ ] Implement offline mode
- [ ] Add data validation
- [ ] Create error recovery flows
- [ ] Test edge cases

### Day 5: Final Testing & Documentation

- [ ] End-to-end testing
- [ ] Performance testing
- [ ] Update user documentation
- [ ] Create release notes
- [ ] Prepare for deployment

## 📊 Key Milestones

| Week | Milestone             | Success Criteria                               |
| ---- | --------------------- | ---------------------------------------------- |
| 1    | Foundation Complete   | HealthKit setup done, Backend ready            |
| 2    | Core Features Working | Game over triggers, State management works     |
| 3    | Recovery System Live  | Distance tracking functional, Progress visible |
| 4    | Feature Complete      | All tests pass, Ready for release              |

## 🧪 Testing Strategy

### Unit Tests

```swift
// Test Coverage Goals
- HealthKitService: 90%
- RecoveryViewModel: 85%
- Game State Logic: 95%
- Distance Calculations: 100%
```

### Integration Tests

- HealthKit data flow
- Backend synchronization
- State persistence
- Progress updates

### User Acceptance Tests

1. New user starts with 1000 health
2. Health decreases with bad habits
3. Game over triggers at 0 health
4. HealthKit permission request works
5. Distance tracking is accurate
6. Progress bar updates correctly
7. 42km completion triggers recovery
8. Health restores to 1000
9. Game returns to normal state

## 🎨 UI/UX Requirements

### Screens & Components

#### 1. Game Over Modal

```
Design Requirements:
- Dark/red theme
- Clear explanation
- Call-to-action button
- Dramatic but not discouraging
```

#### 2. Recovery Progress Screen

```
Design Requirements:
- Progress bar (primary focus)
- Distance metrics
- Time elapsed
- Daily average
- Motivational messages
```

#### 3. Completion Celebration

```
Design Requirements:
- Success animation
- Confetti effect
- Achievement badge
- Share option
```

## 📱 Technical Requirements

### iOS

- iOS 17.0+ (for latest HealthKit features)
- iPhone 12 or newer (recommended)
- Apple Health app installed
- Location services (optional, for outdoor runs)

### Backend

- Node.js 18+
- PostgreSQL with JSON support
- Real-time sync capabilities
- Data validation middleware

## 🚦 Risk Management

### High Risk Items

1. **HealthKit Permission Denial**
   - Mitigation: Provide clear value proposition
   - Fallback: Manual entry option

2. **Data Accuracy**
   - Mitigation: Cross-validate with multiple sources
   - Fallback: Allow data corrections

3. **Cheating/Exploitation**
   - Mitigation: Implement validation rules
   - Fallback: Community reporting system

### Medium Risk Items

1. **Performance Issues**
   - Mitigation: Optimize queries, cache data
2. **Sync Conflicts**
   - Mitigation: Implement conflict resolution

## 📈 Success Metrics

### Launch Metrics (First Month)

- 80% of game-over users start recovery
- 60% complete the marathon challenge
- Average recovery time: 7-10 days
- 90% HealthKit permission grant rate

### Long-term Metrics (3 Months)

- 30% reduction in game-over frequency
- 85% user retention after recovery
- 4.5+ star rating for feature
- 70% feature engagement rate

## 🔄 Post-Launch Iterations

### Version 1.1 (2 weeks post-launch)

- Bug fixes based on user feedback
- Performance optimizations
- UI tweaks

### Version 1.2 (1 month post-launch)

- Add cycling as recovery option
- Implement recovery leaderboard
- Add achievement badges

### Version 2.0 (3 months post-launch)

- Difficulty modes (Half/Full/Ultra)
- Team recovery challenges
- Recovery boosters/power-ups

## 📝 Documentation Needed

1. **User Guide**
   - How the system works
   - HealthKit setup instructions
   - Tips for completing recovery

2. **Technical Documentation**
   - API endpoint specifications
   - HealthKit integration guide
   - State management documentation

3. **FAQ**
   - Common issues and solutions
   - Privacy and data usage
   - Troubleshooting guide

## ✅ Definition of Done

- [ ] All acceptance criteria met
- [ ] Code review completed
- [ ] Unit tests written and passing (>80% coverage)
- [ ] Integration tests passing
- [ ] Documentation updated
- [ ] UI/UX review approved
- [ ] Performance benchmarks met
- [ ] Security review passed
- [ ] Accessibility standards met
- [ ] Beta testing feedback incorporated
- [ ] Release notes prepared
- [ ] Deployment plan ready

## 🎯 Next Steps

1. **Immediate Actions**
   - Set up development environment
   - Create feature branch
   - Begin HealthKit research

2. **Week 1 Goals**
   - Complete foundation setup
   - Have working HealthKit authorization
   - Backend endpoints ready

3. **Communication**
   - Daily standups during development
   - Weekly progress reports
   - Stakeholder demo after Week 3

---

**Feature Owner**: iOS Team  
**Last Updated**: September 2025  
**Status**: Backend foundation complete; PR open

## ✅ Completed This Cycle

- Backend schema and migration for game state and recovery fields
- Endpoints: game-state, recovery-progress, complete-recovery
- Actions router: trigger game over on life <= 0; block actions when not active
- API documentation updated
- DB migrated and tests passing

## 🚀 Next Steps

1. Merge PR #25 into `feature/game-over-config` integration branch
2. iOS scaffolding
   - Add GameState enum/model and GameStateManager
   - HealthKitService: authorization + distance since `gameOverAt`
   - Game Over modal and Recovery progress views
3. Wire backend sync from iOS (progress + completion)
4. Milestones, haptics, and completion celebration
5. Add endpoint tests for new routes (optional) and anti-cheat validations

## 🧭 Execution Plan: Next 10 Days

The items below focus on moving from backend-complete to an end-to-end, testable iOS experience. Tasks are grouped by day ranges with clear ownership, dependencies, and acceptance criteria. Keep commits small and open PRs per sub-scope.

### Day 0–1: Unblock and Scaffold
- [ ] Merge PR #25 into `feature/game-over-config` (Owner: Backend)
- [ ] Create iOS branch `feature/marathon-recovery-ios` (Owner: iOS)
- [ ] Add scaffolds
  - [ ] `GameState` enum + `GameStateManager` (persisted) (Owner: iOS)
  - [ ] `HealthKitService` skeleton: auth + distance since date (Owner: iOS)
  - [ ] `GameOverModal` and `MarathonRecoveryView` stubs (Owner: iOS)
- [ ] Wire build flags, ensure app compiles with stubs (Owner: iOS)

Dependencies
- Apple Developer HealthKit capability enabled; test device with Health app

Acceptance
- App builds; toggling mock state shows modal/recovery stubs

### Day 2–4: Game Over Flow (Client) + Guards
- [ ] Monitor life in BadHabits flow; trigger game over at ≤ 0 (Owner: iOS)
- [ ] Present `GameOverModal` with CTA to start recovery (Owner: iOS)
- [ ] Respect server guard: surface 409s when `gameState != active` (Owner: iOS)
- [ ] Add local state persistence for `gameOverAt` (Owner: iOS)

Acceptance
- Recording bad habit at 0 life shows modal and blocks further actions
- Attempts to log while not active show friendly error mapped from 409

### Day 5–7: HealthKit + Progress Sync
- [ ] Request HealthKit authorization (walking+running) (Owner: iOS)
- [ ] Implement `getDistanceSince(gameOverAt)` with daily aggregation (Owner: iOS)
- [ ] UI: progress bar, distance, percentage, milestones (25/50/75) (Owner: iOS)
- [ ] Backend sync
  - [ ] `GET /game-state` on launch/resume (Owner: iOS)
  - [ ] `PUT /recovery-progress` with cumulative meters (Owner: iOS)
- [ ] Local cache of last-known progress for offline (Owner: iOS)

Acceptance
- With sample Health data, progress updates correctly and persists across relaunch
- Backend reflects cumulative distance; UI matches server values

### Day 8–9: Completion + Celebration
- [ ] Detect 42,195m completion and call `POST /complete-recovery` (Owner: iOS)
- [ ] Restore client state to `active`, health to 1000 (Owner: iOS)
- [ ] Add haptics, confetti, and minimal celebration screen (Owner: iOS)

Acceptance
- Crossing 42.195km reliably restores state, shows celebration, and re-enables gameplay

### Day 10: Edge Cases + Tests
- [ ] Handle HealthKit denied/not determined (copy + settings deeplink) (Owner: iOS)
- [ ] Basic anti-cheat validation on client (e.g., cap >50km/day locally) (Owner: iOS)
- [ ] Unit tests: `GameStateManager`, distance math, completion detection (Owner: iOS)
- [ ] Happy-path integration: progress sync + completion (Owner: iOS)
- [ ] Optional: lightweight endpoint tests for new routes (Owner: Backend)

Acceptance
- Tests pass locally; denied-permission path degrades gracefully with guidance

### Tracking & Deliverables
- Demos: 2 quick screen recordings (modal trigger, progress+completion)
- Docs: Update `docs/GAME_OVER_RECOVERY_SPEC.md` (API notes, auth copy), this roadmap’s checkboxes
- Analytics (optional): simple counters for permission granted, recovery started, recovery completed
