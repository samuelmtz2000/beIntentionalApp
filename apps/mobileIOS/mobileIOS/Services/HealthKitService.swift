import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

final class HealthKitService {
    #if canImport(HealthKit)
    private let healthStore = HKHealthStore()
    #endif

    init() {}

    func requestAuthorization() async throws {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let toRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.workoutType()
        ]
        try await healthStore.requestAuthorization(toShare: [], read: toRead)
        #else
        // No-op on platforms without HealthKit
        #endif
    }

    func distanceSince(date: Date) async throws -> Double {
        #if canImport(HealthKit)
        // Implementation will be added during integration.
        return 0
        #else
        return 0
        #endif
    }
}

