import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = .autoupdatingCurrent
        return formatter
    }()

    enum Screen {
        case splash
        case onboarding
        case home
        case daily
        case endless
        case studio
        case stats
        case themes
        case settings
    }

    struct BetaStatus {
        let launchCount: Int
        let unexpectedCloseCount: Int
        let crashFreeRate: Double
    }

    struct Celebration: Identifiable, Equatable {
        enum Kind: Equatable {
            case dailyFirstClear
            case streakMilestone(Int)
            case endlessMilestone(Int)
            case endlessHighScore(Int)
        }

        let id = UUID()
        let kind: Kind
        let title: String
        let detail: String
    }

    var screen: Screen {
        didSet {
            analytics.trackScreen(screen.analyticsName, enabled: progress.settings.analyticsEnabled)
        }
    }
    var progress: PlayerProgress
    let storage: ProgressStorage
    let library: PuzzleLibrary
    let engine = PuzzleEngine()
    let dailyService = DailyPuzzleService()
    let haptics = HapticsManager()
    let sound = SoundManager()
    let analytics: AnalyticsService
    let diagnostics: DiagnosticsService
    var celebration: Celebration?

    init(
        storage: ProgressStorage = ProgressStorage(),
        library: PuzzleLibrary = .shared,
        analytics: AnalyticsService = AnalyticsService(),
        diagnostics: DiagnosticsService = DiagnosticsService()
    ) {
        self.storage = storage
        self.library = library
        self.analytics = analytics
        self.diagnostics = diagnostics
        let loadedProgress = storage.load()
        self.progress = loadedProgress
        self.screen = loadedProgress.onboardingComplete ? .home : .onboarding
        self.analytics.trackScreen(screen.analyticsName, enabled: loadedProgress.settings.analyticsEnabled)
    }

    func launch() async {
        diagnostics.beginLaunch()
        analytics.trackLaunch(enabled: progress.settings.analyticsEnabled)
        screen = progress.onboardingComplete ? .home : .onboarding
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background:
            diagnostics.markBackgrounded()
        case .active:
            analytics.trackEvent("scene_active", detail: screen.analyticsName, enabled: progress.settings.analyticsEnabled)
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func saveProgress() {
        storage.save(progress)
    }

    func completeOnboarding() {
        progress.onboardingComplete = true
        saveProgress()
        analytics.trackEvent("onboarding_complete", detail: "Tutorial complete", enabled: progress.settings.analyticsEnabled)
        screen = .home
    }

    func currentTheme(for puzzle: Puzzle? = nil) -> ThemeChoice {
        puzzle?.themeOverride ?? progress.selectedTheme
    }

    func presentThemes() {
        analytics.trackEvent("open_themes", detail: progress.selectedTheme.displayName, enabled: progress.settings.analyticsEnabled)
        screen = .themes
    }

    func selectTheme(_ choice: ThemeChoice) {
        progress.selectedTheme = choice
        saveProgress()
        analytics.trackEvent("theme_selected", detail: choice.displayName, enabled: progress.settings.analyticsEnabled)
    }

    func dailyDescriptor(for date: Date = Date()) -> DailyPuzzleDescriptor {
        dailyService.puzzle(for: date, from: library.dailyPool)
    }

    func markStudioSolved(packID: String, puzzle: Puzzle, solveTime: TimeInterval) {
        progress.totalPuzzlesSolved += 1
        progress.studioSolved[packID, default: []].insert(puzzle.id)
        if let parTime = puzzle.parTime, solveTime <= parTime {
            progress.perfectClears += 1
            progress.studioPerfect[packID, default: []].insert(puzzle.id)
        }
        saveProgress()
        analytics.trackEvent("studio_solved", detail: "\(packID):\(puzzle.id) in \(Int(solveTime.rounded()))s", enabled: progress.settings.analyticsEnabled)
    }

    func registerEndlessSolve(chain: Int, solveTime: TimeInterval, puzzle: Puzzle) -> Int {
        let basePoints = 10
        let chainBonus = max(0, (chain - 1) * 3)
        let speedBonus: Int
        if let parTime = puzzle.parTime, solveTime <= parTime {
            speedBonus = max(2, Int((parTime - solveTime).rounded(.down)))
        } else {
            speedBonus = 0
        }

        let awarded = basePoints + chainBonus + speedBonus
        progress.totalPuzzlesSolved += 1
        progress.endlessBestChain = max(progress.endlessBestChain, chain)
        saveProgress()
        analytics.trackEvent("endless_solved", detail: "\(puzzle.id) chain \(chain) award \(awarded)", enabled: progress.settings.analyticsEnabled)
        if chain > 0, chain.isMultiple(of: 5) {
            presentCelebration(
                .init(
                    kind: .endlessMilestone(chain),
                    title: "Run \(chain)",
                    detail: "The line is holding. Keep the run alive."
                )
            )
        }
        return awarded
    }

    func finalizeEndlessRun(score: Int, chain: Int) {
        guard score > 0 || chain > 0 else { return }
        progress.endlessRunsPlayed += 1
        progress.endlessTotalScore += score
        progress.endlessBestChain = max(progress.endlessBestChain, chain)

        let isHighScore = score > progress.endlessHighScore
        progress.endlessHighScore = max(progress.endlessHighScore, score)
        saveProgress()
        analytics.trackEvent("endless_run_finalized", detail: "score \(score), chain \(chain)", enabled: progress.settings.analyticsEnabled)

        if isHighScore && score > 0 {
            presentCelebration(
                .init(
                    kind: .endlessHighScore(score),
                    title: "New High Score",
                    detail: "\(score) points. The run stayed beautifully alive."
                )
            )
        }
    }

    func markDailySolved(_ descriptor: DailyPuzzleDescriptor, swipe: Direction, solveTime: TimeInterval) {
        guard !progress.hasSolvedDaily(on: descriptor.dateKey) else { return }

        progress.totalPuzzlesSolved += 1
        if let last = progress.lastDailySolvedKey, previousDateKey(of: descriptor.dateKey) == last {
            progress.currentStreak += 1
        } else {
            progress.currentStreak = 1
        }

        progress.longestStreak = max(progress.longestStreak, progress.currentStreak)
        progress.lastDailySolvedKey = descriptor.dateKey
        progress.dailyHistory.append(
            DailyCompletionRecord(
                dateKey: descriptor.dateKey,
                puzzleID: descriptor.puzzle.id,
                swipe: swipe,
                solveTime: solveTime,
                timestamp: Date()
            )
        )
        saveProgress()
        analytics.trackEvent("daily_solved", detail: "\(descriptor.puzzle.id) \(swipe.symbol) \(String(format: "%.1fs", solveTime))", enabled: progress.settings.analyticsEnabled)

        let detail = if progress.currentStreak >= 3, progress.currentStreak.isMultiple(of: 5) {
            "First clear logged. Streak \(progress.currentStreak) reached a quiet milestone."
        } else {
            "First clear logged. Streak \(progress.currentStreak)."
        }

        presentCelebration(
            .init(
                kind: .dailyFirstClear,
                title: "Daily Solved",
                detail: detail
            )
        )
    }

    func dismissCelebration() {
        celebration = nil
    }

    func shareText(for descriptor: DailyPuzzleDescriptor, swipe: Direction) -> String {
        let solved = progress.hasSolvedDaily(on: descriptor.dateKey)
        let todaysTime = progress.dailyHistory.first(where: { $0.dateKey == descriptor.dateKey })?.solveTime
        let timeLine = todaysTime.map { String(format: "Time: %.1fs", $0) } ?? "Time: --"
        let header = "One Turn Daily #\(descriptor.puzzleNumber)"
        let status = solved ? "Solved" : "Unsolved"
        let path = "Swipe: \(swipe.symbol)"
        let streak = "Streak: \(progress.currentStreak)"
        let theme = "Theme: \(progress.selectedTheme.displayName)"
        let rating = descriptor.puzzle.difficulty == .elegantBrutal ? "Mood: Elegant Brutal" : "Mood: \(descriptor.puzzle.difficulty.label)"
        return [header, status, path, timeLine, streak, theme, rating].joined(separator: "\n")
    }

    var analyticsSnapshot: AnalyticsSnapshot {
        analytics.snapshot
    }

    var betaStatus: BetaStatus {
        BetaStatus(
            launchCount: diagnostics.snapshot.launchCount,
            unexpectedCloseCount: diagnostics.snapshot.unexpectedCloseCount,
            crashFreeRate: diagnostics.snapshot.crashFreeLaunchRate
        )
    }

    private func presentCelebration(_ celebration: Celebration) {
        self.celebration = celebration
        sound.play(.milestone, enabled: progress.settings.soundEnabled)
        Task {
            try? await Task.sleep(for: .seconds(2.6))
            if self.celebration?.id == celebration.id {
                self.celebration = nil
            }
        }
    }

    private func previousDateKey(of key: String) -> String? {
        guard let date = Self.dayKeyFormatter.date(from: key),
              let previous = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }
        return Self.dayKeyFormatter.string(from: previous)
    }
}

private extension AppModel.Screen {
    var analyticsName: String {
        switch self {
        case .splash: "splash"
        case .onboarding: "onboarding"
        case .home: "home"
        case .daily: "daily"
        case .endless: "endless"
        case .studio: "studio"
        case .stats: "stats"
        case .themes: "themes"
        case .settings: "settings"
        }
    }
}
