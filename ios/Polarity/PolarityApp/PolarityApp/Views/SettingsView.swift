import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var notificationManager: NotificationManager
    @ObservedObject var journalStore: JournalStore

    private var notifyTimeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = settings.notifyHour
                components.minute = settings.notifyMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                settings.notifyHour = components.hour ?? 8
                settings.notifyMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SettingsSection(title: "Notifications", icon: "bell") {
                        Toggle("Daily Reminder", isOn: $settings.notificationsEnabled)
                            .tint(Theme.accent)
                            .onChange(of: settings.notificationsEnabled) { _ in
                                Task {
                                    if settings.notificationsEnabled {
                                        await notificationManager.requestAuthorization()
                                    }
                                    notificationManager.updateServerToggle(settings: settings)
                                }
                            }

                        if settings.notificationsEnabled {
                            hairline
                            DatePicker("Remind me at", selection: notifyTimeBinding, displayedComponents: .hourAndMinute)
                                .tint(Theme.accent)
                        }
                    }

                    SettingsSection(title: "Storage", icon: "icloud") {
                        Toggle("Sync with iCloud", isOn: $settings.iCloudEnabled)
                            .tint(Theme.accent)
                            .onChange(of: settings.iCloudEnabled) { _ in
                                journalStore.refreshStorageLocation()
                            }

                        hairline

                        Text("Your journal stays on-device by default. Enabling iCloud sync stores it in your private iCloud Drive.")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SettingsSection(title: "Appearance", icon: "paintbrush") {
                        Picker("Theme", selection: $settings.appearance) {
                            ForEach(AppAppearance.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(spacing: 5) {
                        Text("Polarity")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(Theme.muted)
                        Text("Free and private. No account, no ads, no tracking.")
                            .font(.caption2)
                            .foregroundColor(Theme.muted.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Text("Inspired by the work of David R. Hawkins. Not affiliated with, or endorsed by, David R. Hawkins or his publishers.")
                            .font(.caption2)
                            .foregroundColor(Theme.muted.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                        if let version = appVersion {
                            Text(version)
                                .font(.caption2)
                                .foregroundColor(Theme.muted.opacity(0.5))
                                .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .readableWidth()
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Settings")
            .onAppear {
                notificationManager.refreshAuthorizationStatus()
            }
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(Theme.muted.opacity(0.15))
            .frame(height: 1)
    }

    private var appVersion: String? {
        let info = Bundle.main.infoDictionary
        guard let version = info?["CFBundleShortVersionString"] as? String else { return nil }
        if let build = info?["CFBundleVersion"] as? String {
            return "Version \(version) (\(build))"
        }
        return "Version \(version)"
    }
}

/// A titled, card-backed group of controls, matching the app's warm card language.
private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title.uppercased(), systemImage: icon)
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundColor(Theme.accentDark)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 14) {
                content
            }
            .foregroundColor(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }
}
