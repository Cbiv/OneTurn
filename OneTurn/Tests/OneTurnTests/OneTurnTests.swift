import Foundation
import Testing
@testable import OneTurn

struct OneTurnTests {
    @Test func mirrorReflectionBehaves() {
        #expect(Direction.up.reflected(by: .mirrorSlash) == .right)
        #expect(Direction.left.reflected(by: .mirrorBackslash) == .up)
    }

    @Test func directionalMechanicsBehave() {
        #expect(TileKind.oneWay(.left).rotatedClockwise() == .oneWay(.up))
        #expect(TileKind.oneWay(.left).flippedHorizontally() == .oneWay(.right))
        #expect(Direction.up.rotatedClockwise() == .right)
    }

    @Test func firstOnboardingPuzzleSolves() {
        let library = PuzzleLibrary()
        let puzzle = library.onboarding[0]
        let result = PuzzleEngine().simulate(puzzle: puzzle, swipe: puzzle.validSolutionDirection)

        #expect(result.solved)
        #expect(result.activated.count == puzzle.objectiveTiles.count)
    }

    @Test func allCuratedPuzzlesHaveExactlyOneSolution() {
        let library = PuzzleLibrary()
        let engine = PuzzleEngine()
        let puzzles =
            library.onboarding +
            library.studioPacks.flatMap(\.puzzles) +
            library.dailyPool +
            library.endlessPool

        for puzzle in puzzles {
            let solutions = engine.solvingConfigurations(for: puzzle)
            #expect(solutions.count == 1, "Expected exactly one solving setup for \(puzzle.id), got \(solutions)")
            #expect(solutions.first?.direction == puzzle.validSolutionDirection)
            #expect(solutions.first?.placedMirrors == puzzle.validPlacedMirrors)
        }
    }

    @Test func dailySelectionIsDeterministic() {
        let library = PuzzleLibrary()
        let service = DailyPuzzleService()
        let date = ISO8601DateFormatter().date(from: "2026-04-06T12:00:00Z")!

        let first = service.puzzle(for: date, from: library.dailyPool)
        let second = service.puzzle(for: date, from: library.dailyPool)

        #expect(first.dateKey == second.dateKey)
        #expect(first.puzzle.id == second.puzzle.id)
        #expect(first.puzzleNumber == second.puzzleNumber)
    }

    @Test func dailyPuzzlesRequireSixPlacements() {
        let library = PuzzleLibrary()
        #expect(!library.dailyPool.isEmpty)
        #expect(library.dailyPool.allSatisfy { $0.placeableMirrorLimit == 6 })
        #expect(library.dailyPool.allSatisfy { $0.validPlacedMirrors.count == 6 })
    }

    @Test func contentPoolsStayLargeEnough() {
        let library = PuzzleLibrary()
        let studioCount = library.studioPacks.flatMap(\.puzzles).count

        #expect(studioCount >= 90)
        #expect(library.endlessPool.count >= 140)
        #expect(library.dailyPool.count >= 56)
    }

    @MainActor
    @Test func placeableMirrorsStartEmptyAndRespectLimit() {
        let library = PuzzleLibrary()
        guard let puzzle = library.endlessPool.first(where: { $0.placeableMirrorLimit == 1 }) else {
            Issue.record("Expected a planning puzzle with one placeable mirror")
            return
        }

        let session = GameSession(
            puzzle: puzzle,
            engine: PuzzleEngine(),
            settings: SettingsState(),
            haptics: HapticsManager(),
            sound: SoundManager(),
            analytics: AnalyticsService(defaults: defaults(named: "session"))
        )
        let placementSpot = puzzle.validPlacedMirrors.keys.first!

        #expect(session.placedMirrors.isEmpty)
        #expect(session.mirrorsRemaining == 1)

        session.cyclePlacement(at: placementSpot)
        #expect(session.placedMirrors[placementSpot] == .mirrorSlash)
        #expect(session.mirrorsRemaining == 0)

        session.cyclePlacement(at: placementSpot)
        #expect(session.placedMirrors[placementSpot] == .mirrorBackslash)

        session.cyclePlacement(at: placementSpot)
        #expect(session.placedMirrors[placementSpot] == nil)
        #expect(session.mirrorsRemaining == 1)
    }

    @MainActor
    @Test func solvingPlanningPuzzleRequiresPlayerPlacement() {
        let library = PuzzleLibrary()
        guard let puzzle = library.dailyPool.first(where: { !$0.validPlacedMirrors.isEmpty }) else {
            Issue.record("Expected a planning puzzle in the daily pool")
            return
        }

        let engine = PuzzleEngine()
        let unsolvedWithoutPlacement = engine.simulate(
            puzzle: puzzle,
            swipe: puzzle.validSolutionDirection,
            placedMirrors: [:]
        )
        let solvedWithPlacement = engine.simulate(
            puzzle: puzzle,
            swipe: puzzle.validSolutionDirection,
            placedMirrors: puzzle.validPlacedMirrors
        )

        #expect(!unsolvedWithoutPlacement.solved)
        #expect(solvedWithPlacement.solved)
    }

    @Test func newMechanicPuzzlesSolveCleanly() {
        let library = PuzzleLibrary()
        let engine = PuzzleEngine()
        let mechanicPuzzles = library.studioPacks
            .flatMap(\.puzzles)
            .filter { puzzle in
                puzzle.tiles.contains {
                    switch $0.kind {
                    case .oneWay, .rotatorClockwise:
                        true
                    default:
                        false
                    }
                }
            }

        #expect(!mechanicPuzzles.isEmpty)
        #expect(mechanicPuzzles.allSatisfy { engine.simulate(puzzle: $0, swipe: $0.validSolutionDirection, placedMirrors: $0.validPlacedMirrors).solved })
    }

    @MainActor
    @Test func dailySolveBuildsStreakAndShareText() {
        let defaults = UserDefaults(suiteName: "OneTurnTests-\(UUID().uuidString)")!
        let appModel = AppModel(storage: ProgressStorage(defaults: defaults), library: .shared)
        let descriptor = appModel.dailyDescriptor(for: ISO8601DateFormatter().date(from: "2026-04-07T12:00:00Z")!)

        appModel.markDailySolved(descriptor, swipe: descriptor.puzzle.validSolutionDirection, solveTime: 18)

        #expect(appModel.progress.currentStreak == 1)
        #expect(appModel.progress.hasSolvedDaily(on: descriptor.dateKey))
        #expect(appModel.shareText(for: descriptor, swipe: descriptor.puzzle.validSolutionDirection).contains("Streak: 1"))
    }

    @MainActor
    @Test func endlessScoringTracksChains() {
        let defaults = UserDefaults(suiteName: "OneTurnTests-\(UUID().uuidString)")!
        let appModel = AppModel(storage: ProgressStorage(defaults: defaults), library: .shared)
        let puzzle = appModel.library.endlessPool[0]

        let first = appModel.registerEndlessSolve(chain: 1, solveTime: 4, puzzle: puzzle)
        let second = appModel.registerEndlessSolve(chain: 2, solveTime: 3, puzzle: puzzle)
        appModel.finalizeEndlessRun(score: first + second, chain: 2)

        #expect(second > first)
        #expect(appModel.progress.endlessBestChain == 2)
        #expect(appModel.progress.endlessHighScore == first + second)
    }

    @MainActor
    @Test func diagnosticsTracksUnexpectedCloses() {
        let diagnostics = DiagnosticsService(defaults: defaults(named: "diagnostics"))

        diagnostics.beginLaunch()
        diagnostics.beginLaunch()

        #expect(diagnostics.snapshot.launchCount == 2)
        #expect(diagnostics.snapshot.unexpectedCloseCount == 1)

        diagnostics.markBackgrounded()
        #expect(diagnostics.snapshot.launchInProgress == false)
    }

    @MainActor
    @Test func analyticsTracksEventsWhenEnabled() {
        let analytics = AnalyticsService(defaults: defaults(named: "analytics"))

        analytics.trackLaunch(enabled: true)
        analytics.trackScreen("home", enabled: true)
        analytics.trackEvent("daily_solved", detail: "sample", enabled: true)

        #expect(analytics.snapshot.launchCount == 1)
        #expect(analytics.snapshot.screenViews["home"] == 1)
        #expect(analytics.snapshot.eventCounts["daily_solved"] == 1)
    }

    private func defaults(named name: String) -> UserDefaults {
        let suiteName = "OneTurnTests-\(name)-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
