import SwiftUI

@main
struct OneTurnApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(appModel: appModel)
                .task {
                    await appModel.launch()
                }
                .onChange(of: scenePhase) { _, phase in
                    appModel.handleScenePhase(phase)
                }
        }
    }
}

struct RootView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                GradientBackdrop(
                    theme: appModel.currentTheme(),
                    animated: appModel.screen == .home || appModel.screen == .themes || appModel.screen == .settings
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                currentScreen
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if let celebration = appModel.celebration {
                    CelebrationBanner(
                        celebration: celebration,
                        theme: ThemeDefinition.definition(for: appModel.currentTheme())
                    ) {
                        appModel.dismissCelebration()
                    }
                    .padding(.top, max(12, proxy.safeAreaInsets.top + 10))
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                }
            }
            .background(ThemeDefinition.definition(for: appModel.currentTheme()).background.first ?? .black)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.28), value: appModel.celebration?.id)
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch appModel.screen {
        case .onboarding:
            OnboardingView(appModel: appModel)
        case .home:
            HomeView(appModel: appModel)
        case .daily:
            DailyPuzzleView(appModel: appModel)
        case .endless:
            EndlessModeView(appModel: appModel)
        case .studio:
            StudioModeView(appModel: appModel)
        case .stats:
            StatsView(appModel: appModel)
        case .themes:
            ThemePickerView(appModel: appModel)
        case .settings:
            SettingsView(appModel: appModel)
        case .splash:
            OnboardingView(appModel: appModel)
        }
    }
}

private struct CelebrationBanner: View {
    let celebration: AppModel.Celebration
    let theme: ThemeDefinition
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: 14) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(theme.accent)
                    .frame(width: 28, height: 28)
                    .background(theme.boardFill, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(celebration.title)
                        .font(.headline)
                        .foregroundStyle(theme.textPrimary)
                    Text(celebration.detail)
                        .font(.footnote)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(theme.panelStroke, lineWidth: 1)
            )
            .shadow(color: theme.panelShadow.opacity(0.25), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(celebration.title). \(celebration.detail)")
    }

    private var iconName: String {
        switch celebration.kind {
        case .dailyFirstClear:
            "sun.max"
        case .streakMilestone:
            "flame"
        case .endlessMilestone:
            "sparkles"
        case .endlessHighScore:
            "crown"
        }
    }
}
