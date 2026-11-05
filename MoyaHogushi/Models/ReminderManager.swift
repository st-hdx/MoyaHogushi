import Foundation
import UserNotifications

/// 毎日のリマインド通知(Pro 機能)。
final class ReminderManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var hour: Int
    @Published private(set) var minute: Int
    @Published private(set) var permissionDenied = false

    private static let identifier = "dailyReminder"
    private let defaults = UserDefaults.standard
    private let center = UNUserNotificationCenter.current()

    init() {
        isEnabled = defaults.bool(forKey: "reminderEnabled")
        hour = defaults.object(forKey: "reminderHour") as? Int ?? 21
        minute = defaults.object(forKey: "reminderMinute") as? Int ?? 0
    }

    @MainActor
    func setEnabled(_ on: Bool) async {
        if on {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            permissionDenied = !granted
            isEnabled = granted
        } else {
            permissionDenied = false
            isEnabled = false
        }
        persistAndReschedule()
    }

    func setTime(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
        persistAndReschedule()
    }

    /// Pro が切れたときに、予約済みの通知を残さないために呼ぶ。
    @MainActor
    func disableBecauseNotPro() {
        guard isEnabled else { return }
        isEnabled = false
        persistAndReschedule()
    }

    private func persistAndReschedule() {
        defaults.set(isEnabled, forKey: "reminderEnabled")
        defaults.set(hour, forKey: "reminderHour")
        defaults.set(minute, forKey: "reminderMinute")

        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "もやほぐし"
        content.body = "今日、もやもやしたことはあった? 3分だけ整理してみよう。"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
    }
}
