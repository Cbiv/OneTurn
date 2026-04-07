import Foundation
import OSLog

@MainActor
final class AnalyticsService {
    private let logger = Logger(subsystem: "com.christopherbivins.oneturn", category: "analytics")
    private let defaults: UserDefaults
    private let storageKey = "OneTurn.analytics.snapshot"

    private(set) var snapshot: AnalyticsSnapshot

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AnalyticsSnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = AnalyticsSnapshot()
        }
    }

    func trackLaunch(enabled: Bool) {
        guard enabled else { return }
        snapshot.launchCount += 1
        record(name: "app_launch", detail: "Launch \(snapshot.launchCount)")
    }

    func trackScreen(_ name: String, enabled: Bool) {
        guard enabled else { return }
        snapshot.incrementScreen(name)
        save()
    }

    func trackEvent(_ name: String, detail: String, enabled: Bool) {
        guard enabled else { return }
        record(name: name, detail: detail)
    }

    private func record(name: String, detail: String) {
        snapshot.recordEvent(name: name, detail: detail)
        logger.log("\(name, privacy: .public): \(detail, privacy: .public)")
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
