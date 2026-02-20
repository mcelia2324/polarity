import Foundation
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    var notificationManager: NotificationManager?
    var settingsStore: SettingsStore?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        if let manager = notificationManager, let settings = settingsStore {
            manager.setDeviceToken(token, settings: settings)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        return
    }
}
