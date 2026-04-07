import SwiftUI

struct OnboardingView: View {
    @Bindable var appModel: AppModel
    @State private var index = 0
    @State private var session: GameSession?

    var body: some View {
        let puzzle = appModel.library.onboarding[index]
        let activeSession = session ?? makeSession(for: puzzle)

        PuzzlePlayView(
            appModel: appModel,
            session: activeSession,
            heading: "Onboarding \(index + 1) of \(appModel.library.onboarding.count)",
            subheading: puzzle.title,
            hintEnabled: false,
            onHome: { appModel.screen = .home },
            onSolved: { _, _ in
                if index == appModel.library.onboarding.count - 1 {
                    appModel.completeOnboarding()
                } else {
                    index += 1
                    session = makeSession(for: appModel.library.onboarding[index])
                }
            }
        ) {
                Text(onboardingCopy)
                    .font(.footnote)
                    .foregroundStyle(ThemeDefinition.definition(for: appModel.currentTheme()).textSecondary)
                    .multilineTextAlignment(.center)
        }
        .onAppear {
            if session == nil {
                session = activeSession
            }
        }
    }

    private var onboardingCopy: String {
        switch index {
        case 0: "Swipe once."
        case 1: "Light every mark."
        default: "Use the board."
        }
    }

    private func makeSession(for puzzle: Puzzle) -> GameSession {
        GameSession(
            puzzle: puzzle,
            engine: appModel.engine,
            settings: appModel.progress.settings,
            haptics: appModel.haptics,
            sound: appModel.sound,
            analytics: appModel.analytics
        )
    }
}
