import SwiftUI

struct SettingsView: View {
    @Bindable var appModel: AppModel

    private var theme: ThemeDefinition {
        ThemeDefinition.definition(for: appModel.currentTheme())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button {
                        appModel.screen = .home
                    } label: {
                        Image(systemName: "house")
                            .font(.headline)
                    }
                    .buttonStyle(OrbButtonStyle(theme: theme))

                    Text("Settings")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                }
                .padding(.top, 20)

                GlassCard(theme: theme) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Appearance")
                            .font(.headline)
                            .foregroundStyle(theme.textPrimary)

                        Text("Choose the atmosphere that frames every board.")
                            .font(.footnote)
                            .foregroundStyle(theme.textSecondary)

                        Button {
                            appModel.presentThemes()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appModel.progress.selectedTheme.displayName)
                                        .font(.headline)
                                    Text("Open theme gallery")
                                        .font(.footnote)
                                        .foregroundStyle(theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.footnote.weight(.semibold))
                            }
                            .foregroundStyle(theme.textPrimary)
                            .padding(16)
                            .background(theme.boardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .buttonStyle(PillActionButtonStyle(theme: theme))
                    }
                }

                GlassCard(theme: theme) {
                    VStack(alignment: .leading, spacing: 18) {
                        settingsToggle("Reduced motion", binding: $appModel.progress.settings.reducedMotion)
                        settingsToggle("Haptics", binding: $appModel.progress.settings.hapticsEnabled)
                        settingsToggle("Sound", binding: $appModel.progress.settings.soundEnabled)
                        settingsToggle("High contrast", binding: $appModel.progress.settings.highContrast)
                        settingsToggle("Daily hints", binding: $appModel.progress.settings.allowDailyHints)
                        settingsToggle("Anonymous analytics", binding: $appModel.progress.settings.analyticsEnabled)
                    }
                }

                GlassCard(theme: theme) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Beta Readiness")
                            .font(.headline)
                            .foregroundStyle(theme.textPrimary)
                        Text("Crash-free rate \(Int((appModel.betaStatus.crashFreeRate * 100).rounded()))% across \(appModel.betaStatus.launchCount) launches.")
                            .font(.footnote)
                            .foregroundStyle(theme.textSecondary)

                        if appModel.betaStatus.unexpectedCloseCount > 0 {
                            Text("Unexpected closes observed: \(appModel.betaStatus.unexpectedCloseCount)")
                                .font(.footnote)
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: appModel.progress.settings) { _, _ in
            appModel.saveProgress()
        }
    }

    private func settingsToggle(_ title: String, binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(title)
                .foregroundStyle(theme.textPrimary)
        }
        .tint(theme.accent)
    }
}
