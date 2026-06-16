import Foundation
import HealthKit

enum HealthConnectionState {
    case notAvailable
    case notDetermined
    case denied
    case authorized
}

final class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published private(set) var connectionState: HealthConnectionState = .notDetermined

    init() {
        refreshConnectionState()
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func refreshConnectionState() {
        guard isAvailable else {
            connectionState = .notAvailable
            return
        }

        guard
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let basalEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
            let vo2Type = HKObjectType.quantityType(forIdentifier: .vo2Max)
        else {
            connectionState = .notAvailable
            return
        }

        let statuses = [
            healthStore.authorizationStatus(for: sleepType),
            healthStore.authorizationStatus(for: activeEnergyType),
            healthStore.authorizationStatus(for: basalEnergyType),
            healthStore.authorizationStatus(for: vo2Type)
        ]

        if statuses.contains(.sharingDenied) {
            connectionState = .denied
            return
        }

        if statuses.allSatisfy({ $0 == .notDetermined }) {
            connectionState = .notDetermined
            return
        }

        if statuses.contains(.sharingAuthorized) {
            connectionState = .authorized
            return
        }

        connectionState = .notDetermined
    }

    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitManagerError.notAvailable }

        guard
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let basalEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
            let vo2Type = HKObjectType.quantityType(forIdentifier: .vo2Max)
        else {
            throw HealthKitManagerError.typeUnavailable
        }

        let readTypes: Set<HKObjectType> = [sleepType, activeEnergyType, basalEnergyType, vo2Type]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: HealthKitManagerError.authorizationFailed)
                }
            }
        }

        await MainActor.run {
            self.refreshConnectionState()
        }
    }

    func fetchTodayMetrics() async throws -> (sleepHours: Double?, trainingStrain: Double?, vo2Max: Double?, activeEnergyKcal: Double?, basalEnergyKcal: Double?) {
        guard isAvailable else { throw HealthKitManagerError.notAvailable }

        await MainActor.run {
            self.refreshConnectionState()
        }

        let sleepHours = try await fetchLastNightSleepHours()
        let activeEnergyKcal = try await fetchTodayActiveEnergy()
        let basalEnergyKcal = try await fetchTodayBasalEnergy()
        let vo2Max = try await fetchLatestVO2Max()

        let strain: Double?
        if let activeEnergyKcal {
            let normalized = sqrt(max(0, activeEnergyKcal) / 25.0) * 3.5
            strain = min(21.0, max(0.0, normalized))
        } else {
            strain = nil
        }

        return (sleepHours, strain, vo2Max, activeEnergyKcal, basalEnergyKcal)
    }

    private func fetchLastNightSleepHours() async throws -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitManagerError.typeUnavailable
        }

        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard let startWindow = calendar.date(byAdding: .hour, value: -14, to: startOfToday) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: startWindow, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let totalSeconds = (samples as? [HKCategorySample])?
                    .filter { sample in
                        sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                        || sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                        || sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                        || sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    }
                    .reduce(0.0) { partial, sample in
                        partial + sample.endDate.timeIntervalSince(sample.startDate)
                    } ?? 0

                continuation.resume(returning: totalSeconds > 0 ? (totalSeconds / 3600.0) : nil)
            }

            healthStore.execute(query)
        }
    }

    private func fetchTodayActiveEnergy() async throws -> Double? {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitManagerError.typeUnavailable
        }

        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func fetchTodayBasalEnergy() async throws -> Double? {
        guard let basalEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            throw HealthKitManagerError.typeUnavailable
        }

        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: basalEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func fetchLatestVO2Max() async throws -> Double? {
        guard let vo2Type = HKObjectType.quantityType(forIdentifier: .vo2Max) else {
            throw HealthKitManagerError.typeUnavailable
        }

        let now = Date()
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -60, to: now) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: vo2Type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let sample = samples?.first as? HKQuantitySample
                let unit = HKUnit(from: "ml/kg*min")
                let value = sample?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }
}

enum HealthKitManagerError: LocalizedError {
    case notAvailable
    case typeUnavailable
    case authorizationFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Health data is not available on this device."
        case .typeUnavailable:
            return "Required Health data types are unavailable."
        case .authorizationFailed:
            return "Health data authorization failed."
        }
    }
}
