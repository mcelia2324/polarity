import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private var deviceToken: String?

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
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
