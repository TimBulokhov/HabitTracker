//
//  AppDelegate.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AnalyticsService.activate()
        NotificationManager.shared.requestAuthorization()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TrackerModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                _ = error as NSError
                // print("Unresolved error \(error), \((error as NSError).userInfo)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    // Сохраняем уведомление во внутренний список, не показываем alert
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let rawCategory = content.userInfo["category"] as? String ?? content.subtitle
        let normalizedCategory = rawCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let type = content.userInfo["type"] as? String ?? "unknown"
        if ["overdue", "eventStarted", "deadline", "deadlineChanged"].contains(type) {
            print("[AppDelegate] Adding internal notification for type: \(type), id: \(notification.request.identifier)")
            if !NotificationStore.shared.notifications.contains(where: { $0.notificationId == notification.request.identifier }) {
                NotificationStore.shared.addNotification(title: content.title, body: content.body, category: normalizedCategory, notificationId: notification.request.identifier, type: type)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
        completionHandler([]) // Не показывать системный баннер
    }
    // Сохраняем уведомление во внутренний список даже если оно пришло в background
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        let rawCategory = content.userInfo["category"] as? String ?? content.subtitle
        let normalizedCategory = rawCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let type = content.userInfo["type"] as? String ?? "unknown"
        if ["overdue", "eventStarted", "deadline", "deadlineChanged"].contains(type) {
            print("[AppDelegate] Adding internal notification for type: \(type), id: \(response.notification.request.identifier)")
            if !NotificationStore.shared.notifications.contains(where: { $0.notificationId == response.notification.request.identifier }) {
                NotificationStore.shared.addNotification(title: content.title, body: content.body, category: normalizedCategory, notificationId: response.notification.request.identifier, type: type)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
        
        // Открываем экран уведомлений
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let tabBarController = window.rootViewController as? UITabBarController {
                tabBarController.selectedIndex = 2 // Индекс экрана уведомлений
            }
        }
        
        completionHandler()
    }
    
}

