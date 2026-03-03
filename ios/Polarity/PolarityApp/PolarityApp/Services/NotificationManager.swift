import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private static let tokenKey = "apnsDeviceToken"

    private var deviceToken: String? {
        didSet {
            if let token = deviceToken {
                UserDefaults.standard.set(token, forKey: Self.tokenKey)
            }
        }
    }

    init() {
        // Restore persisted token so toggle/re-register works after restart
        deviceToken = UserDefaults.standard.string(forKey: Self.tokenKey)
    }

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    /// Call on every app launch to re-register if notifications are enabled.
    func registerIfEnabled(settings: SettingsStore) {
        guard settings.notificationsEnabled else { return }
        refreshAuthorizationStatus()
        UIApplication.shared.registerForRemoteNotifications()

        // Re-register with the backend using the persisted token
        if let token = deviceToken {
            Task {
                await APIClient.shared.registerDevice(
                    token: token,
                    timezone: TimeZone.current.identifier,
                    notifyHour: settings.notifyHour,
                    notifyMinute: settings.notifyMinute,
                    enabled: settings.notificationsEnabled
                )
            }
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            return
        }
        refreshAuthorizationStatus()
    }

    func setDeviceToken(_ token: String, settings: SettingsStore) {
        deviceToken = token
        Task {
            await APIClient.shared.registerDevice(
                token: token,
                timezone: TimeZone.current.identifier,
                notifyHour: settings.notifyHour,
                notifyMinute: settings.notifyMinute,
                enabled: settings.notificationsEnabled
            )
        }
    }

    func updateServerToggle(settings: SettingsStore) {
        guard let token = deviceToken else { return }
        Task {
            await APIClient.shared.toggleDevice(token: token, enabled: settings.notificationsEnabled)
        }
    }
}
