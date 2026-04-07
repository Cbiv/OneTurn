import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class GameSession {
    enum Outcome {
        case solved
        case failed
    }

    let puzzle: Puzzle
    let engine: PuzzleEngine
    let settings: SettingsState
    let haptics: HapticsManager
    let sound: SoundManager
    let analytics: AnalyticsService

    var tokenPosition: Position
    var activated: Set<Position> = []
    var broken: Set<Position> = []
    var traversed: Set<Position>
    var mirroredFlash: Position?
    var placedMirrors: [Position: TileKind]
    var locked = false
    var hasPlayed = false
    var solvedDirection: Direction?
    var outcome: Outcome?
    var completionRatio = 0.0
    var elapsedTime: TimeInterval = 0
    var tokenAnimationDuration = 0.05
    private var startDate = Date()

    init(
        puzzle: Puzzle,
        engine: PuzzleEngine,
        settings: SettingsState,
        haptics: HapticsManager,
        sound: SoundManager,
        analytics: AnalyticsService
    ) {
        self.puzzle = puzzle
        self.engine = engine
        self.settings = settings
        self.haptics = haptics
        self.sound = sound
        self.analytics = analytics
        self.tokenPosition = puzzle.startPosition
        self.traversed = [puzzle.startPosition]
        self.placedMirrors = [:]
    }

    func restart() {
        tokenPosition = puzzle.startPosition
        activated = []
        broken = []
        traversed = [puzzle.startPosition]
        mirroredFlash = nil
        placedMirrors = [:]
        locked = false
        hasPlayed = false
        solvedDirection = nil
        outcome = nil
        completionRatio = 0
        elapsedTime = 0
        tokenAnimationDuration = 0.05
        startDate = Date()
    }

    func commitSwipe(_ direction: Direction, onComplete: @escaping (Bool, Direction, TimeInterval) -> Void) {
        guard !locked, !hasPlayed else { return }
        locked = true
        hasPlayed = true
        solvedDirection = direction
        elapsedTime = Date().timeIntervalSince(startDate)
        haptics.impact(.soft, enabled: settings.hapticsEnabled)
        sound.play(.commit, enabled: settings.soundEnabled)
        analytics.trackEvent(
            "swipe_committed",
            detail: "\(puzzle.id) \(direction.symbol) with \(placedMirrors.count) placements",
            enabled: settings.analyticsEnabled
        )

        let result = engine.simulate(puzzle: puzzle, swipe: direction, placedMirrors: placedMirrors)
        Task {
            let delay = animationDelay(for: result.steps.count)
            let duration = tokenAnimationDuration(for: delay)
            tokenAnimationDuration = duration
            var previousActivated = activated
            var previousBroken = broken

            for (index, step) in result.steps.enumerated() {
                withAnimation(.linear(duration: duration)) {
                    tokenPosition = step.position
                }
                applyBoardState(step, at: index, totalSteps: result.steps.count)

                if step.activated.count > previousActivated.count {
                    sound.play(.objective, enabled: settings.soundEnabled)
                }
                if step.broken.count > previousBroken.count {
                    sound.play(.objective, enabled: settings.soundEnabled)
                }
                previousActivated = step.activated
                previousBroken = step.broken

                if step.mirroredPosition != nil {
                    mirroredFlash = step.mirroredPosition
                    haptics.impact(.light, enabled: settings.hapticsEnabled)
                    sound.play(.mirror, enabled: settings.soundEnabled)
                }

                try? await Task.sleep(for: delay)
                if step.mirroredPosition != nil {
                    mirroredFlash = nil
                }
            }

            activated = result.activated
            broken = result.broken
            traversed = result.traversed
            completionRatio = result.completionRatio
            outcome = result.solved ? .solved : .failed
            elapsedTime = max(Date().timeIntervalSince(startDate), elapsedTime)
            locked = false

            if result.solved {
                haptics.notification(.success, enabled: settings.hapticsEnabled)
                sound.play(.success, enabled: settings.soundEnabled)
            } else {
                haptics.notification(.warning, enabled: settings.hapticsEnabled)
                sound.play(.failure, enabled: settings.soundEnabled)
            }

            analytics.trackEvent(
                result.solved ? "puzzle_solved" : "puzzle_failed",
                detail: "\(puzzle.id) steps \(result.steps.count) ratio \(String(format: "%.2f", result.completionRatio))",
                enabled: settings.analyticsEnabled
            )

            onComplete(result.solved, direction, elapsedTime)
        }
    }

    func cyclePlacement(at position: Position) {
        guard !locked, !hasPlayed, puzzle.canPlaceMirror(at: position) else { return }

        switch placedMirrors[position] {
        case .mirrorSlash:
            placedMirrors[position] = .mirrorBackslash
        case .mirrorBackslash:
            placedMirrors[position] = nil
        default:
            guard placedMirrors.count < puzzle.placeableMirrorLimit else { return }
            placedMirrors[position] = .mirrorSlash
        }
        sound.play(.placement, enabled: settings.soundEnabled)
        analytics.trackEvent(
            "mirror_placed",
            detail: "\(puzzle.id) at \(position.row),\(position.column)",
            enabled: settings.analyticsEnabled
        )
    }

    var mirrorsRemaining: Int {
        max(0, puzzle.placeableMirrorLimit - placedMirrors.count)
    }

    private func applyBoardState(_ step: SimulationStep, at index: Int, totalSteps: Int) {
        guard shouldRefreshBoardState(at: index, step: step, totalSteps: totalSteps) else { return }

        if activated != step.activated {
            activated = step.activated
        }
        if broken != step.broken {
            broken = step.broken
        }
        if traversed != step.traversed {
            traversed = step.traversed
        }
    }

    private func shouldRefreshBoardState(at index: Int, step: SimulationStep, totalSteps: Int) -> Bool {
        if settings.reducedMotion {
            return true
        }
        if index == totalSteps - 1 || step.mirroredPosition != nil {
            return true
        }

        let stride: Int
        switch totalSteps {
        case 0...18:
            stride = 1
        case 19...30:
            stride = 2
        case 31...44:
            stride = 3
        default:
            stride = 4
        }

        return index.isMultiple(of: stride)
    }

    private func animationDelay(for stepCount: Int) -> Duration {
        guard !settings.reducedMotion else {
            return .milliseconds(18)
        }

        switch stepCount {
        case 0...10:
            return .milliseconds(68)
        case 11...20:
            return .milliseconds(54)
        case 21...36:
            return .milliseconds(40)
        default:
            return .milliseconds(28)
        }
    }

    private func tokenAnimationDuration(for delay: Duration) -> Double {
        let component = delay.components
        let seconds = Double(component.seconds) + (Double(component.attoseconds) / 1_000_000_000_000_000_000)
        return max(0.018, seconds * 0.96)
    }
}
