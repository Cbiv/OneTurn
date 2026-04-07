import Foundation

@MainActor
final class DiagnosticsService {
    private let defaults: UserDefaults
    private let storageKey = "OneTurn.diagnostics.snapshot"

    private(set) var snapshot: DiagnosticsSnapshot

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(DiagnosticsSnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = DiagnosticsSnapshot()
        }
    }

    func beginLaunch() {
        if snapshot.launchInProgress {
            snapshot.unexpectedCloseCount += 1
            snapshot.lastUnexpectedCloseDate = Date()
        }
        snapshot.launchCount += 1
        snapshot.launchInProgress = true
        snapshot.lastLaunchDate = Date()
        save()
    }

    func markBackgrounded() {
        guard snapshot.launchInProgress else { return }
        snapshot.launchInProgress = false
        snapshot.lastCleanBackgroundDate = Date()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
