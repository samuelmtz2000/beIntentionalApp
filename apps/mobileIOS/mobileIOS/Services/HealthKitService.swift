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
        guard HKHealthStore.isHealthDataAvailable() else { return 0 }
        let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let predicate = HKQuery.predicateForSamples(withStart: date, end: Date(), options: .strictStartDate)
        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error { cont.resume(throwing: error); return }
                let total = (samples as? [HKQuantitySample])?.reduce(0.0) { acc, s in
                    acc + s.quantity.doubleValue(for: HKUnit.meter())
                } ?? 0
                cont.resume(returning: total)
            }
            healthStore.execute(query)
        }
#else
        return 0
#endif
    }

    func hasConfiguredAccess() async -> Bool {
#if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let toRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.workoutType()
        ]
        return await withCheckedContinuation { cont in
            healthStore.getRequestStatusForAuthorization(toShare: [], read: toRead) { status, _ in
                cont.resume(returning: status == .unnecessary)
            }
        }
#else
        return false
#endif
    }
}
