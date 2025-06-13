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
        guard let deadline = tracker.deadline else { return }
        
        // Удаляем старые уведомления о начале события
        let eventIdPrefix = "tracker-\(tracker.id)-eventStarted"
        // Для дедлайна используем только уникальный префикс
        let deadlineIdPrefix = "tracker-\(tracker.id)-deadline-"
        
        if tracker.isIrregular {
            // Для нерегулярных событий: удаляем старые eventStarted и только после этого создаём новое уведомление
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let idsToRemove = requests.filter { $0.identifier.hasPrefix(eventIdPrefix) }.map { $0.identifier }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
                NotificationStore.shared.removeNotifications(withPrefix: eventIdPrefix, keepHistory: false)
                DispatchQueue.main.async {
                    let eventId = "tracker-\(tracker.id)-eventStarted-\(Int(deadline.timeIntervalSince1970))"
                    let eventContent = UNMutableNotificationContent()
                    eventContent.title = "Событие началось!"
                    eventContent.body = "\(tracker.name)\nПроект: \(normalizedCategory)"
                    eventContent.sound = UNNotificationSound.default
                    eventContent.userInfo = ["category": normalizedCategory, "type": "eventStarted"]
                    let now = Date()
                    let trigger: UNNotificationTrigger
                    if deadline <= now {
                        trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    } else {
                        trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(deadline.timeIntervalSince(now), 1), repeats: false)
                    }
                    let request = UNNotificationRequest(identifier: eventId, content: eventContent, trigger: trigger)
                    self.center.add(request) { error in
                        if let error = error {
                            print("[Notification] Error scheduling event started notification: \(error)")
                        } else {
                            print("[Notification] Event started notification scheduled successfully")
                        }
                    }
                }
            }
        } else {
            // Для обычных трекеров: удаляем только deadline-уведомления по уникальному префиксу
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let idsToRemove = requests.filter { $0.identifier.hasPrefix(deadlineIdPrefix) }.map { $0.identifier }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
                NotificationStore.shared.removeNotifications(withPrefix: deadlineIdPrefix, keepHistory: true)
                // ... создание deadline-уведомления ...
                let deadlineId = "tracker-\(tracker.id)-deadline-\(Int(deadline.timeIntervalSince1970))"
                let deadlineContent = UNMutableNotificationContent()
                deadlineContent.title = "Скоро дедлайн!"
                deadlineContent.body = "\(tracker.name)\nПроект: \(normalizedCategory)\nСтатус: \(tracker.status)"
                deadlineContent.sound = UNNotificationSound.default
                deadlineContent.userInfo = ["category": normalizedCategory, "type": "deadline"]
                let now = Date()
                let timeInterval = deadline.timeIntervalSince(now) - 3600 // За час до дедлайна
                if timeInterval > 0 {
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                    let request = UNNotificationRequest(identifier: deadlineId, content: deadlineContent, trigger: trigger)
                    self.center.add(request) { error in
                        if let error = error {
                            print("[Notification] Error scheduling deadline notification: \(error)")
                        } else {
                            print("[Notification] Deadline notification scheduled successfully")
                        }
                    }
                }
            }
        }
    }
    
    // Новое уведомление об изменении срока
    func scheduleDeadlineChangedNotification(for tracker: Tracker, category: String, newDeadline: Date) {
        print("[DEBUG] scheduleDeadlineChangedNotification called for tracker: \(tracker.id), category: \(category), newDeadline: \(newDeadline)")
        let normalizedCategory = normalizeCategory(category)
        let id = "tracker-\(tracker.id)-deadline-changed-\(Int(Date().timeIntervalSince1970))"
        // Удаляем только pending notification requests о смене дедлайна, историю в NotificationStore не трогаем
        let deadlineChangedIdPrefix = "tracker-\(tracker.id)-deadline-changed"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove = requests.filter { $0.identifier.hasPrefix(deadlineChangedIdPrefix) }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
        // НЕ удаляем из NotificationStore, чтобы история сохранялась
        let content = UNMutableNotificationContent()
        if tracker.isIrregular {
            content.title = "Дата события изменилась"
            content.body = "\(tracker.name)\nПроект: \(normalizedCategory)\nНовая дата: \(formatDate(newDeadline))"
        } else {
            content.title = "Срок задачи изменен"
            content.body = "\(tracker.name)\nПроект: \(normalizedCategory)\nНовый срок: \(formatDate(newDeadline))"
        }
        content.sound = .default
        content.userInfo = ["category": normalizedCategory, "type": "deadlineChanged"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] Error scheduling deadline changed notification: \(error)")
            } else {
                print("[Notification] Deadline changed notification scheduled successfully")
            }
        }
        // Always add to notification store for history
        NotificationStore.shared.addNotification(title: content.title, body: content.body, category: normalizedCategory, notificationId: id, type: "deadlineChanged")
        // Сбросить флаг, чтобы при новом дедлайне снова пришло уведомление о просрочке
        let overdueSentKey = "overdueSent_\(tracker.id.uuidString)"
        UserDefaults.standard.set(false, forKey: overdueSentKey)
        // Для нерегулярных событий: удалить старые eventStarted-уведомления и создать новое на новую дату
        if tracker.isIrregular {
            let eventIdPrefix = "tracker-\(tracker.id)-eventStarted"
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let idsToRemove = requests.filter { $0.identifier.hasPrefix(eventIdPrefix) }.map { $0.identifier }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
            }
            NotificationStore.shared.removeNotifications(withPrefix: eventIdPrefix, keepHistory: true)
            scheduleOrUpdateDeadlineOrEventNotification(for: tracker, category: category)
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
        content.userInfo = ["category": normalizedCategory, "type": "created"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] Error scheduling creation notification: \(error)")
            } else {
                print("[Notification] Creation notification scheduled successfully")
            }
        }
        NotificationStore.shared.addNotification(title: content.title, body: content.body, category: normalizedCategory, notificationId: id, type: "created")
    }
    
    func scheduleStatusChangedNotification(for tracker: Tracker, category: String) {
        let normalizedCategory = normalizeCategory(category)
        let id = "tracker-\(tracker.id)-status-\(Int(Date().timeIntervalSince1970))"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Статус задачи изменён"
        content.body = "\(tracker.name)\nПроект: \(normalizedCategory)\nТекущий статус: \(tracker.status)"
        content.sound = .default
        content.userInfo = ["category": normalizedCategory, "type": "statusChanged"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] Error scheduling status changed notification: \(error)")
            } else {
                print("[Notification] Status changed notification scheduled successfully")
            }
        }
        // Add to notification store for history
        NotificationStore.shared.addNotification(title: content.title, body: content.body, category: normalizedCategory, notificationId: id, type: "statusChanged")
    }
    
    func scheduleCategoryChangedNotification(for tracker: Tracker, newCategory: String, oldCategory: String) {
        let normalizedNewCategory = normalizeCategory(newCategory)
        let normalizedOldCategory = normalizeCategory(oldCategory)
        // Удаляем старые уведомления о переносе
        let categoryChangedNewIdPrefix = "tracker-\(tracker.id)-category-new"
        let categoryChangedOldIdPrefix = "tracker-\(tracker.id)-category-old"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove = requests.filter { $0.identifier.hasPrefix(categoryChangedNewIdPrefix) || $0.identifier.hasPrefix(categoryChangedOldIdPrefix) }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
        NotificationStore.shared.removeNotifications(withPrefix: categoryChangedNewIdPrefix)
        NotificationStore.shared.removeNotifications(withPrefix: categoryChangedOldIdPrefix)
        
        // Уведомление для новой категории
        let newId = "tracker-\(tracker.id)-category-new-\(Int(Date().timeIntervalSince1970))"
        center.removePendingNotificationRequests(withIdentifiers: [newId])
        let newContent = UNMutableNotificationContent()
        newContent.title = tracker.isIrregular ? "Событие перенесено в другой проект" : "Задача перенесена в другой проект"
        if tracker.isIrregular {
            newContent.body = "\(tracker.name)\nНовый проект: \(normalizedNewCategory)\nРанее: \(normalizedOldCategory)"
        } else {
            newContent.body = "\(tracker.name)\nНовый проект: \(normalizedNewCategory)\nРанее: \(normalizedOldCategory)\nТекущий статус: \(tracker.status)"
        }
        newContent.sound = .default
        newContent.userInfo = ["category": normalizedNewCategory]
        let newTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let newRequest = UNNotificationRequest(identifier: newId, content: newContent, trigger: newTrigger)
        center.add(newRequest) { error in
            if let error = error {
                print("[Notification] Error scheduling category changed notification (new): \(error)")
            } else {
                print("[Notification] Category changed notification scheduled successfully (new)")
            }
        }
        NotificationStore.shared.addNotification(title: newContent.title, body: newContent.body, category: normalizedNewCategory, notificationId: newId, type: "categoryChanged")
        
        // Уведомление для старой категории
        let oldId = "tracker-\(tracker.id)-category-old-\(Int(Date().timeIntervalSince1970))"
        center.removePendingNotificationRequests(withIdentifiers: [oldId])
        let oldContent = UNMutableNotificationContent()
        oldContent.title = tracker.isIrregular ? "Событие перенесено в другой проект" : "Задача перенесена в другой проект"
        if tracker.isIrregular {
            oldContent.body = "\(tracker.name)\nНовый проект: \(normalizedNewCategory)"
        } else {
            oldContent.body = "\(tracker.name)\nНовый проект: \(normalizedNewCategory)\nТекущий статус: \(tracker.status)"
        }
        oldContent.sound = .default
        oldContent.userInfo = ["category": normalizedOldCategory]
        let oldTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let oldRequest = UNNotificationRequest(identifier: oldId, content: oldContent, trigger: oldTrigger)
        center.add(oldRequest) { error in
            if let error = error {
                print("[Notification] Error scheduling category changed notification (old): \(error)")
            } else {
                print("[Notification] Category changed notification scheduled successfully (old)")
            }
        }
        NotificationStore.shared.addNotification(title: oldContent.title, body: oldContent.body, category: normalizedOldCategory, notificationId: oldId, type: "categoryChanged")
    }
    
    func scheduleOverdueNotification(for tracker: Tracker, category: String) {
        let normalizedCategory = normalizeCategory(category)
        let id = "tracker-\(tracker.id)-overdue"
        
        // Удаляем все старые уведомления о просрочке для этого трекера
        let overdueIdPrefix = "tracker-\(tracker.id)-overdue"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove = requests.filter { $0.identifier.hasPrefix(overdueIdPrefix) }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
        
        // Удаляем из хранилища все старые уведомления о просрочке для этого трекера
        NotificationStore.shared.removeNotifications(withPrefix: overdueIdPrefix)
        
        let content = UNMutableNotificationContent()
        content.title = "Время вышло. Задача просрочена!"
        content.body = "\(tracker.name)\nПроект: \(normalizedCategory)\nСтатус: \(tracker.status)"
        content.sound = UNNotificationSound.default
        content.userInfo = ["category": normalizedCategory, "type": "overdue"]
        
        // Отправляем уведомление сразу, так как дедлайн уже наступил
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[Notification] Error scheduling overdue notification: \(error)")
            } else {
                print("[Notification] Overdue notification scheduled successfully")
            }
        }
    }
    
    func removeAllNotifications(for tracker: Tracker) {
        let prefixes = [
            "tracker-\(tracker.id)-eventStarted",
            "tracker-\(tracker.id)-deadline",
            "tracker-\(tracker.id)-overdue",
            "tracker-\(tracker.id)-deadline-changed",
            "tracker-\(tracker.id)-status",
            "tracker-\(tracker.id)-category-new",
            "tracker-\(tracker.id)-category-old"
        ]
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove = requests.filter { request in
                prefixes.contains { prefix in
                    request.identifier.hasPrefix(prefix)
                }
            }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
        
        // Удаляем из хранилища, но сохраняем историю
        for prefix in prefixes {
            NotificationStore.shared.removeNotifications(withPrefix: prefix, keepHistory: true)
        }
        // Ставим флаг, чтобы не создавать уведомления снова до следующего изменения дедлайна
        let overdueSentKey = "overdueSent_\(tracker.id.uuidString)"
        UserDefaults.standard.set(true, forKey: overdueSentKey)
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
    let type: String
    var isRead: Bool
}

final class NotificationStore {
    static let shared = NotificationStore()
    private let userDefaults = UserDefaults.standard
    private let notificationsKey = "notifications"
    private(set) var notifications: [InternalNotification] = []
    
    private init() {
        load()
    }
    
    func addNotification(title: String, body: String, category: String, notificationId: String, type: String) {
        let notification = InternalNotification(
            id: UUID(),
            notificationId: notificationId,
            title: title,
            body: body,
            date: Date(),
            category: category,
            type: type,
            isRead: false
        )
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
        NotificationCenter.default.post(name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
    }
    
    func markAsRead(_ id: UUID) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].isRead = true
            save()
            NotificationCenter.default.post(name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
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
    
    func removeNotifications(withPrefix prefix: String, keepHistory: Bool = false) {
        if keepHistory {
            // Only remove from pending notifications, keep in history
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let idsToRemove = requests.filter { $0.identifier.hasPrefix(prefix) }.map { $0.identifier }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
            }
        } else {
            notifications.removeAll { $0.notificationId.hasPrefix(prefix) }
            save()
            NotificationCenter.default.post(name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(notifications) {
            userDefaults.set(data, forKey: notificationsKey)
        }
    }
    
    private func load() {
        if let data = userDefaults.data(forKey: notificationsKey),
           let loadedNotifications = try? JSONDecoder().decode([InternalNotification].self, from: data) {
            notifications = loadedNotifications
        }
    }
}
