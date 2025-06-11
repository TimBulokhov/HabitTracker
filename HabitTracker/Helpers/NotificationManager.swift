import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    private func normalizeCategory(_ category: String) -> String {
        let normalized = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized
    }
    
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[Notification] Error: \(error)")
            }
            print("[Notification] Permission granted: \(granted)")
        }
    }
    
    // Универсальный метод для дедлайна/начала события
    func scheduleOrUpdateDeadlineOrEventNotification(for tracker: Tracker, category: String) {
        let normalizedCategory = normalizeCategory(category)
        let id: String
        if tracker.isIrregular {
            id = "tracker-\(tracker.id)-eventStarted"
            center.removePendingNotificationRequests(withIdentifiers: [id])
            guard let deadline = tracker.deadline else { return }
            let content = UNMutableNotificationContent()
            content.title = "Событие началось!"
            content.body = "\(tracker.name)\nПроект: \(normalizedCategory)"
            content.sound = .default
            content.userInfo = ["category": normalizedCategory]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(deadline.timeIntervalSinceNow, 1), repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("[Notification] Error scheduling event started notification: \(error)")
                } else {
                    print("[Notification] Event started notification scheduled successfully")
                }
            }
        } else {
            id = "tracker-\(tracker.id)-deadline"
            center.removePendingNotificationRequests(withIdentifiers: [id])
            guard let deadline = tracker.deadline else { return }
            let content = UNMutableNotificationContent()
            content.title = tracker.name
            content.body = "Проект: \(normalizedCategory)\nСкоро крайний срок выполнения задачи — \(formatDate(deadline))"
            content.sound = .default
            content.userInfo = ["category": normalizedCategory]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(deadline.timeIntervalSinceNow - 3600, 1), repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("[Notification] Error scheduling deadline notification: \(error)")
                } else {
                    print("[Notification] Deadline notification scheduled successfully")
                }
            }
        }
    }
    
    func scheduleCreationNotification(for tracker: Tracker, category: String) {
        let normalizedCategory = normalizeCategory(category)
        let id = "tracker-\(tracker.id)-created"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = tracker.isIrregular ? "Новое событие создано" : "Новая задача создана"
        content.body = "\(tracker.name)\nПроект: \(normalizedCategory)\n" + (tracker.deadline != nil ? (tracker.isIrregular ? "Начало события: " : "Крайний срок: ") + formatDate(tracker.deadline!) : "")
        content.sound = .default
        content.userInfo = ["category": normalizedCategory]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] Error scheduling creation notification: \(error)")
            } else {
                print("[Notification] Creation notification scheduled successfully")
            }
        }
    }
    
    func scheduleStatusChangedNotification(for tracker: Tracker, category: String) {
        let normalizedCategory = normalizeCategory(category)
        let id = "tracker-\(tracker.id)-status"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Статус задачи изменён"
        content.body = "\(tracker.name)\nПроект: \(normalizedCategory)\nТекущий статус: \(tracker.status)"
        content.sound = .default
        content.userInfo = ["category": normalizedCategory]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] Error scheduling status changed notification: \(error)")
            } else {
                print("[Notification] Status changed notification scheduled successfully")
            }
        }
    }
    
    func scheduleCategoryChangedNotification(for tracker: Tracker, newCategory: String, oldCategory: String) {
        let normalizedNewCategory = normalizeCategory(newCategory)
        let normalizedOldCategory = normalizeCategory(oldCategory)
        let id = "tracker-\(tracker.id)-category"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = tracker.isIrregular ? "Событие перенесено в другой проект" : "Задача перенесена в другой проект"
        if tracker.isIrregular {
            content.body = "\(tracker.name)\nНовый проект: \(normalizedNewCategory)"
        } else {
            content.body = "\(tracker.name)\nНовый проект: \(normalizedNewCategory)\nТекущий статус: \(tracker.status)"
        }
        content.sound = .default
        content.userInfo = ["category": normalizedOldCategory]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] Error scheduling category changed notification: \(error)")
            } else {
                print("[Notification] Category changed notification scheduled successfully")
            }
        }
    }
    
    func scheduleOverdueNotification(for tracker: Tracker, category: String) {
        let normalizedCategory = normalizeCategory(category)
        let id = "tracker-\(tracker.id)-overdue"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Время вышло. Задача просрочена!"
        content.body = "\(tracker.name)\nПроект: \(normalizedCategory)\nСтатус: \(tracker.status)"
        content.sound = .default
        content.userInfo = ["category": normalizedCategory]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] Error scheduling overdue notification: \(error)")
            } else {
                print("[Notification] Overdue notification scheduled successfully")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Internal Notification Model & Store

struct InternalNotification: Codable, Identifiable {
    let id: UUID
    let notificationId: String // идентификатор из UNNotificationRequest
    let title: String
    let body: String
    let date: Date
    let category: String
    var isRead: Bool
}

final class NotificationStore {
    static let shared = NotificationStore()
    private let userDefaultsKey = "InternalNotifications"
    private(set) var notifications: [InternalNotification] = []
    
    private init() {
        load()
    }
    
    func addNotification(title: String, body: String, category: String, notificationId: String) {
        if notifications.contains(where: { $0.notificationId == notificationId }) {
            return
        }
        let notification = InternalNotification(id: UUID(), notificationId: notificationId, title: title, body: body, date: Date(), category: category, isRead: false)
        notifications.append(notification)
        save()
        NotificationCenter.default.post(name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
    }
    
    func markAllAsRead() {
        notifications = notifications.map { n in
            var n = n
            n.isRead = true
            return n
        }
        save()
    }
    
    func markAsRead(_ id: UUID) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].isRead = true
            save()
        }
    }
    
    func unreadCount() -> Int {
        notifications.filter { !$0.isRead }.count
    }
    
    func notificationsByCategory() -> [String: [InternalNotification]] {
        Dictionary(grouping: notifications, by: { $0.category })
    }
    
    func clearAll() {
        notifications.removeAll()
        save()
        NotificationCenter.default.post(name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } else {
            print("[DEBUG] NotificationStore.save: failed to encode notifications")
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let loadedNotifications = try? JSONDecoder().decode([InternalNotification].self, from: data) {
            notifications = loadedNotifications
        } else {
            print("[DEBUG] NotificationStore.load: no saved notifications found")
        }
    }
}
