//
//  TabBarController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

// MARK: - UITabBarController

final class TabBarController: UITabBarController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        generateTabBar()
        tabBarAppearance()
        tabBarSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNotificationsBadge()
        NotificationCenter.default.addObserver(self, selector: #selector(updateBadgeFromStore), name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("InternalNotificationStoreChanged"), object: nil)
    }
    
    // MARK: - Private methods
    
    private func generateTabBar() {
        let trackerViewController = TrackersViewController()
        let statisticsViewController = StatisticsViewController()
        let statisticsViewModel = StatsViewModel()
        let settingsViewController = SettingsViewController()
        
        // Инициализируем StatisticsViewController с ViewModel
        statisticsViewController.initialize(viewModel: statisticsViewModel)
        
        // Устанавливаем делегат для обновления статистики
        trackerViewController.delegateStatistic = statisticsViewModel
        
        // Загружаем начальные данные
        try? statisticsViewModel.fetchStatistics()
        
        let notificationsViewController = NotificationsViewController()
        viewControllers = [
            generateVC(
                viewController: trackerViewController,
                title: NSLocalizedString("trackerTitle", comment: "trackerTitle"),
                image: UIImage(named: "trackersIcon")
            ),
            generateVC(
                viewController: statisticsViewController,
                title: NSLocalizedString("statisticsTitle", comment: "statisticsTitle"),
                image: UIImage(named: "statsIcon")
            ),
            generateVC(
                viewController: notificationsViewController,
                title: NSLocalizedString("notifications", comment: "notifications"),
                image: UIImage(systemName: "bell.badge")
            ),
            generateVC(
                viewController: settingsViewController,
                title: NSLocalizedString("profile", comment: "profile"),
                image: UIImage(systemName: "gear")
            )
        ]
        updateNotificationsBadge()
    }
    
    private func tabBarSetup() {
        tabBar.layer.borderWidth = 0.3
        tabBar.layer.borderColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.2).cgColor
        tabBar.clipsToBounds = true
    }
    
    private func generateVC(viewController: UIViewController, title: String, image: UIImage?) ->
    UIViewController {
        viewController.tabBarItem.title = title
        viewController.tabBarItem.image = image
        return viewController
    }
    
    private func tabBarAppearance() {
        let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBar.standardAppearance = tabBarAppearance
    }
    
    private func updateNotificationsBadge() {
        guard let items = tabBar.items, items.count > 2 else { return }
        let unread = NotificationStore.shared.unreadCount()
        items[2].badgeValue = unread > 0 ? "\(unread)" : nil
    }
    
    @objc private func updateBadgeFromStore() {
        updateNotificationsBadge()
    }
}
