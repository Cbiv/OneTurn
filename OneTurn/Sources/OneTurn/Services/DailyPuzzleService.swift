import Foundation

struct DailyPuzzleDescriptor {
    var dateKey: String
    var puzzleNumber: Int
    var puzzle: Puzzle
}

struct DailyPuzzleService {
    private let calendar = Calendar(identifier: .gregorian)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func puzzle(for date: Date, from pool: [Puzzle]) -> DailyPuzzleDescriptor {
        let normalized = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month, .day], from: normalized)
        let daySeed = (components.year ?? 0) * 10_000 + (components.month ?? 0) * 100 + (components.day ?? 0)
        let index = abs(daySeed) % max(pool.count, 1)
        return DailyPuzzleDescriptor(
            dateKey: Self.dateFormatter.string(from: normalized),
            puzzleNumber: daySeed,
            puzzle: pool[index]
        )
    }
}
