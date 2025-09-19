# Game Over & Running Challenge System - Technical Specification

## Overview

When a player's health reaches 0, the game enters a "Game Over" state. To recover and continue playing, the user must complete a real-world running challenge distance (default 42.195 km, configurable per user) by running/walking, tracked through Apple Health integration.

## Features

### 1. Game State Management

#### States
```typescript
enum GameState {
  ACTIVE = "active",        // Normal gameplay
  GAME_OVER = "game_over",  // Health reached 0
  RECOVERY = "recovery"     // Running challenge to recover
}
```

#### Initial Setup
- New users start with 1000 health points
- Game state is "ACTIVE"

### 2. Game Over Trigger

#### Detection
- Monitor health points after each bad habit recording
- Trigger game over when health ≤ 0

#### Actions on Game Over
1. Update game state to "GAME_OVER"
2. Record timestamp of game over
3. Display game over modal
4. Disable recording of bad habits
5. Present running challenge (dynamic target from user config)
6. Header: show skull icon instead of heart while in game over; heart displays out of 1000 in normal states

### 3. HealthKit Integration

#### Permissions Required
```swift
// Info.plist
NSHealthShareUsageDescription: "Habit Hero needs access to your workout data to track your marathon recovery progress."

// HealthKit Types
HKQuantityType.distanceWalkingRunning
HKWorkoutType.workoutType()
```

#### Data Queries
- Query running + walking distance from game over date
- Aggregate daily distances
- Update progress in real-time when app becomes active

### 4. Running Challenge System

#### Requirements
- **Distance Required**: dynamic per user (User.runningChallengeTarget, default 42.195 km)
- **Valid Activities**: Running, Walking (from HealthKit)
- **Time Frame**: From game over date until completion
- **Progress Tracking**: Persistent, synced with backend

#### UI Components

##### Game Over Modal
```
┌─────────────────────────────────┐
│        💀 GAME OVER 💀          │
│                                 │
│   Your health has reached 0!    │
│                                 │
│   To continue playing, you must │
│   complete the running challenge│
│   (target in km) by running or  │
│   walking.                      │
│                                 │
│   [Start Recovery Challenge]    │
└─────────────────────────────────┘
```

##### Running Challenge View
```
┌─────────────────────────────────┐
│    🏃 Running Challenge 🏃       │
│                                 │
│   Distance Progress             │
│   ████████░░░░░░░░░ 21.5/<target>km│
│                                 │
│   Started: Nov 15, 2024         │
│   Days Elapsed: 3               │
│   Daily Average: 7.2 km         │
│                                 │
│   Keep going! You're halfway!   │
└─────────────────────────────────┘
```

### 5. Backend Data Model

#### User Model Extensions
```javascript
{
  // Existing fields...
  "health": 1000,
  "game_state": "active",
  "game_over_date": null,
  "recovery_started_at": null,
  "recovery_distance": 0,
  "recovery_completed_at": null,
  "total_game_overs": 0
}
```

#### API Endpoints

##### Get Game State
```
GET /api/users/:id/game-state
Response: {
  "state": "recovery",
  "health": 0,
  "game_over_date": "2024-11-15T10:30:00Z",
  "recovery_started_at": "2024-11-15T10:35:00Z",
  "recovery_distance": 21500,  // meters
  "recovery_target": 42195,    // meters (dynamic per user)
  "recovery_percentage": 51
}
```

##### Update Recovery Progress
```
PUT /api/users/:id/recovery-progress
Body: {
  "distance": 21500  // meters
}
Response: {
  "recovery_distance": 21500,
  "recovery_percentage": 51,
  "remaining_distance": 20695,
  "is_complete": false
}
```

##### Complete Recovery
```
POST /api/users/:id/complete-recovery
Response: {
  "game_state": "active",
  "health": 1000,
  "recovery_completed_at": "2024-11-18T14:22:00Z",
  "message": "Congratulations! Your health has been restored!"
}
```

### 6. iOS Implementation

#### HealthKit Service
```swift
class HealthKitService {
    private let healthStore = HKHealthStore()
    
    func requestAuthorization() async throws
    func getDistanceSince(date: Date) async throws -> Double
    func startObservingWorkouts()
    func stopObservingWorkouts()
}
```

#### Recovery View Model
```swift
class RecoveryViewModel: ObservableObject {
    @Published var totalDistance: Double = 0
    @Published var targetDistance: Double = 42195 // updated from server/config
    @Published var progressPercentage: Double = 0
    @Published var isComplete: Bool = false
    @Published var dailyDistances: [Date: Double] = [:]
}
```

### 7. User Experience Flow

#### Game Over Flow
1. Health reaches 0 during bad habit recording
2. Immediate modal appears explaining game over
3. User taps "Start Recovery Challenge"
4. Request HealthKit permissions if not granted
5. Show recovery progress view
6. Begin tracking distance

#### Recovery Flow
1. App queries HealthKit on launch/resume
2. Updates progress bar with current distance
3. Shows encouraging messages at milestones (25%, 50%, 75%)
4. Syncs progress with backend
5. Celebrates completion at 42.195km

#### Completion Flow (UI‑first)
1. Detection of target reached
2. Show celebration modal with confetti immediately
3. On modal dismiss, finalize with backend (POST complete‑recovery)
4. Health restored to 1000 and game state returns to "ACTIVE"
5. Banner hidden; heart shown; bad habits re‑enabled
6. Achievement unlocked (if applicable)

### 8. Edge Cases & Considerations

#### HealthKit Access Denied
- Show alternative: "Please enable Health access in Settings to track your recovery"
- Provide manual entry option (with verification requirements)

#### No HealthKit Data Available
- Handle users without Apple Watch or fitness tracking
- Consider allowing manual workout entry with photo proof

#### Cheating Prevention
- Validate reasonable daily distances (max 50km/day)
- Check for data consistency
- Require minimum number of days (e.g., can't complete 42km in one session)

#### Progress Persistence
- Store progress locally and sync with backend
- Handle offline scenarios
- Recover from app crashes/terminations

### 9. Visual Design

#### Color Scheme
- Game Over: Red/Dark tones (#FF5252)
- Recovery: Orange/Yellow gradient (#FFA726 → #FFD54F)
- Completion: Green/Success (#4CAF50)

#### Animations
- Progress bar with smooth updates
- Milestone celebrations (confetti at 25%, 50%, 75%)
- Completion animation (full-screen celebration)

### 10. Testing Requirements

#### Unit Tests
- Distance calculation accuracy
- Progress percentage calculations
- State transition logic
- Recovery completion detection

#### Integration Tests
- HealthKit data retrieval
- Backend sync functionality
- Progress persistence
- State recovery after app restart

#### User Acceptance Tests
- Complete game over flow
- Track real workouts
- Verify progress updates
- Test completion and restoration
- Edge case scenarios

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] HealthKit integration setup
- [ ] Basic game state management
- [ ] Backend model updates

### Phase 2: Core Features (Week 2)
- [ ] Game over detection and UI
- [ ] Recovery progress tracking
- [ ] HealthKit data queries

### Phase 3: Polish (Week 3)
- [ ] Progress visualization
- [ ] Animations and celebrations
- [ ] Edge case handling

### Phase 4: Testing (Week 4)
- [ ] Comprehensive testing
- [ ] Bug fixes
- [ ] Performance optimization

## Success Metrics

- **Engagement**: % of users who complete recovery after game over
- **Time to Recovery**: Average days to complete 42km
- **Retention**: Users who continue playing after recovery
- **Feature Adoption**: % of users who grant HealthKit access

## Future Enhancements

1. **Difficulty Modes**
   - Easy: 21km (Half Marathon)
   - Normal: 42km (Full Marathon)
   - Hard: 100km (Ultra Marathon)

2. **Team Challenges**
   - Group recovery where friends can contribute distance

3. **Alternative Recovery Methods**
   - Other exercises (cycling, swimming)
   - Meditation minutes
   - Community service hours

4. **Recovery Boosters**
   - In-app purchases to reduce required distance
   - Earned through achievements

5. **Leaderboards**
   - Fastest recovery times
   - Most recoveries completed
   - Longest streak without game over
