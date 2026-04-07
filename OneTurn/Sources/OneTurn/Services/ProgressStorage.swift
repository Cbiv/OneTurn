import Foundation

struct ProgressStorage {
    private let defaults: UserDefaults
    private let key = "one-turn-progress-v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PlayerProgress {
        guard
            let data = defaults.data(forKey: key),
            let progress = try? JSONDecoder().decode(PlayerProgress.self, from: data)
        else {
            return PlayerProgress()
        }
        return progress
    }

    func save(_ progress: PlayerProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }
}
