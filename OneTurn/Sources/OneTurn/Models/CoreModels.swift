import Foundation

enum Direction: String, Codable, CaseIterable, Hashable {
    case up
    case down
    case left
    case right

    var vector: (row: Int, column: Int) {
        switch self {
        case .up: (-1, 0)
        case .down: (1, 0)
        case .left: (0, -1)
        case .right: (0, 1)
        }
    }

    var symbol: String {
        switch self {
        case .up: "↑"
        case .down: "↓"
        case .left: "←"
        case .right: "→"
        }
    }

    func reflected(by kind: TileKind) -> Direction {
        switch kind {
        case .mirrorSlash:
            switch self {
            case .up: .right
            case .right: .up
            case .down: .left
            case .left: .down
            }
        case .mirrorBackslash:
            switch self {
            case .up: .left
            case .left: .up
            case .down: .right
            case .right: .down
            }
        default:
            self
        }
    }

    func rotatedClockwise() -> Direction {
        switch self {
        case .up: .right
        case .right: .down
        case .down: .left
        case .left: .up
        }
    }

    var opposite: Direction {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }
}

struct Position: Hashable, Codable {
    var row: Int
    var column: Int

    func moved(_ direction: Direction) -> Position {
        Position(row: row + direction.vector.row, column: column + direction.vector.column)
    }
}

enum TileKind: Hashable, Codable {
    case empty
    case wall
    case stop
    case paint(required: Bool)
    case gate(required: Bool)
    case mirrorSlash
    case mirrorBackslash
    case breakable
    case socket
    case oneWay(Direction)
    case rotatorClockwise

    var isObjective: Bool {
        switch self {
        case .paint(let required), .gate(let required):
            required
        default:
            false
        }
    }

    var isMirror: Bool {
        switch self {
        case .mirrorSlash, .mirrorBackslash:
            true
        default:
            false
        }
    }
}

struct Tile: Hashable, Codable {
    var position: Position
    var kind: TileKind
}

enum DifficultyBand: String, Codable, CaseIterable, Hashable {
    case obvious
    case clean
    case clever
    case tricky
    case elegantBrutal

    var label: String {
        switch self {
        case .obvious: "Obvious"
        case .clean: "Clean"
        case .clever: "Clever"
        case .tricky: "Tricky"
        case .elegantBrutal: "Elegant Brutal"
        }
    }
}

enum GameMode: String, Codable, Hashable {
    case onboarding
    case daily
    case endless
    case studio
}

enum ThemeChoice: String, Codable, CaseIterable, Hashable {
    case nocturne
    case paperBloom
    case electricQuiet

    var displayName: String {
        switch self {
        case .nocturne: "Nocturne"
        case .paperBloom: "Paper Bloom"
        case .electricQuiet: "Electric Quiet"
        }
    }
}

struct Puzzle: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var width: Int
    var height: Int
    var tiles: [Tile]
    var startPosition: Position
    var validSolutionDirection: Direction
    var validPlacedMirrors: [Position: TileKind]
    var difficulty: DifficultyBand
    var modeType: GameMode
    var themeOverride: ThemeChoice?
    var parTime: TimeInterval?
    var hintText: String?
    var placeableMirrorLimit: Int

    var objectiveTiles: [Tile] {
        tiles.filter { $0.kind.isObjective }
    }

    var placeableMirrorPositions: [Position] {
        return (0..<height).flatMap { row in
            (0..<width).compactMap { column in
                let position = Position(row: row, column: column)
                guard position != startPosition else { return nil }
                let kind = tile(at: position)
                return (kind == .empty || kind == .socket) ? position : nil
            }
        }
    }

    func tile(at position: Position) -> TileKind {
        tiles.first(where: { $0.position == position })?.kind ?? .empty
    }

    func canPlaceMirror(at position: Position) -> Bool {
        placeableMirrorLimit > 0 && placeableMirrorPositions.contains(position)
    }

    func contains(_ position: Position) -> Bool {
        (0..<height).contains(position.row) && (0..<width).contains(position.column)
    }

    func transformed(
        id: String,
        title: String? = nil,
        rotateClockwise turns: Int = 0,
        flipHorizontally: Bool = false,
        mode: GameMode? = nil
    ) -> Puzzle {
        var result = self
        result.id = id
        result.title = title ?? self.title
        result.modeType = mode ?? modeType

        for _ in 0..<(turns % 4 + 4) % 4 {
            result = result.rotatedClockwise()
        }

        if flipHorizontally {
            result = result.flippedHorizontally()
        }

        return result
    }

    private func rotatedClockwise() -> Puzzle {
        let rotatedTiles = tiles.map { tile in
            Tile(
                position: Position(
                    row: tile.position.column,
                    column: height - 1 - tile.position.row
                ),
                kind: tile.kind.rotatedClockwise()
            )
        }

        return Puzzle(
            id: id,
            title: title,
            width: height,
            height: width,
            tiles: rotatedTiles,
            startPosition: Position(row: startPosition.column, column: height - 1 - startPosition.row),
            validSolutionDirection: validSolutionDirection.rotatedClockwise(),
            validPlacedMirrors: Dictionary(uniqueKeysWithValues: validPlacedMirrors.map { position, kind in
                (
                    Position(row: position.column, column: height - 1 - position.row),
                    kind.rotatedClockwise()
                )
            }),
            difficulty: difficulty,
            modeType: modeType,
            themeOverride: themeOverride,
            parTime: parTime,
            hintText: hintText,
            placeableMirrorLimit: placeableMirrorLimit
        )
    }

    private func flippedHorizontally() -> Puzzle {
        let flippedTiles = tiles.map { tile in
            Tile(
                position: Position(row: tile.position.row, column: width - 1 - tile.position.column),
                kind: tile.kind.flippedHorizontally()
            )
        }

        return Puzzle(
            id: id,
            title: title,
            width: width,
            height: height,
            tiles: flippedTiles,
            startPosition: Position(row: startPosition.row, column: width - 1 - startPosition.column),
            validSolutionDirection: validSolutionDirection.flippedHorizontally(),
            validPlacedMirrors: Dictionary(uniqueKeysWithValues: validPlacedMirrors.map { position, kind in
                (
                    Position(row: position.row, column: width - 1 - position.column),
                    kind.flippedHorizontally()
                )
            }),
            difficulty: difficulty,
            modeType: modeType,
            themeOverride: themeOverride,
            parTime: parTime,
            hintText: hintText,
            placeableMirrorLimit: placeableMirrorLimit
        )
    }
}

struct PuzzlePack: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var subtitle: String
    var puzzles: [Puzzle]
}

struct SettingsState: Codable, Hashable {
    var reducedMotion = false
    var hapticsEnabled = true
    var soundEnabled = false
    var highContrast = false
    var allowDailyHints = false
    var analyticsEnabled = true
}

struct DailyCompletionRecord: Codable, Hashable {
    var dateKey: String
    var puzzleID: String
    var swipe: Direction
    var solveTime: TimeInterval
    var timestamp: Date
}

struct PlayerProgress: Codable, Hashable {
    var onboardingComplete = false
    var currentStreak = 0
    var longestStreak = 0
    var lastDailySolvedKey: String?
    var dailyHistory: [DailyCompletionRecord] = []
    var endlessHighScore = 0
    var endlessBestChain = 0
    var endlessRunsPlayed = 0
    var endlessTotalScore = 0
    var totalPuzzlesSolved = 0
    var perfectClears = 0
    var studioSolved: [String: Set<String>] = [:]
    var studioPerfect: [String: Set<String>] = [:]
    var selectedTheme: ThemeChoice = .nocturne
    var settings = SettingsState()

    func hasSolvedDaily(on dateKey: String) -> Bool {
        dailyHistory.contains(where: { $0.dateKey == dateKey })
    }

    func averageDailySolveTime() -> TimeInterval? {
        guard !dailyHistory.isEmpty else { return nil }
        return dailyHistory.map(\.solveTime).reduce(0, +) / Double(dailyHistory.count)
    }

    func bestDailySolveTime() -> TimeInterval? {
        dailyHistory.map(\.solveTime).min()
    }

    func averageEndlessScore() -> Double? {
        guard endlessRunsPlayed > 0 else { return nil }
        return Double(endlessTotalScore) / Double(endlessRunsPlayed)
    }
}

struct AnalyticsEventSummary: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var detail: String
    var timestamp: Date

    init(id: UUID = UUID(), name: String, detail: String, timestamp: Date = Date()) {
        self.id = id
        self.name = name
        self.detail = detail
        self.timestamp = timestamp
    }
}

struct AnalyticsSnapshot: Codable, Hashable {
    var launchCount = 0
    var screenViews: [String: Int] = [:]
    var eventCounts: [String: Int] = [:]
    var recentEvents: [AnalyticsEventSummary] = []

    mutating func incrementScreen(_ name: String) {
        screenViews[name, default: 0] += 1
    }

    mutating func recordEvent(name: String, detail: String) {
        eventCounts[name, default: 0] += 1
        recentEvents.insert(AnalyticsEventSummary(name: name, detail: detail), at: 0)
        recentEvents = Array(recentEvents.prefix(12))
    }
}

struct DiagnosticsSnapshot: Codable, Hashable {
    var launchCount = 0
    var unexpectedCloseCount = 0
    var launchInProgress = false
    var lastLaunchDate: Date?
    var lastCleanBackgroundDate: Date?
    var lastUnexpectedCloseDate: Date?

    var crashFreeLaunchRate: Double {
        guard launchCount > 0 else { return 1 }
        return max(0, 1 - (Double(unexpectedCloseCount) / Double(launchCount)))
    }
}

extension TileKind {
    func rotatedClockwise() -> TileKind {
        switch self {
        case .mirrorSlash:
            .mirrorBackslash
        case .mirrorBackslash:
            .mirrorSlash
        case .oneWay(let direction):
            .oneWay(direction.rotatedClockwise())
        default:
            self
        }
    }

    func flippedHorizontally() -> TileKind {
        switch self {
        case .mirrorSlash:
            .mirrorBackslash
        case .mirrorBackslash:
            .mirrorSlash
        case .oneWay(let direction):
            .oneWay(direction.flippedHorizontally())
        default:
            self
        }
    }
}

extension Direction {
    func flippedHorizontally() -> Direction {
        switch self {
        case .left: .right
        case .right: .left
        default: self
        }
    }
}
