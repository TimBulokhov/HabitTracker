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
    
    // MARK: - Private methods
    
    private func generateTabBar() {
        let trackerViewController = TrackersViewController()
        let statisticsViewController = StatisticsViewController()
        let statisticsViewModel = StatsViewModel()
        statisticsViewController.initialize(viewModel: statisticsViewModel)
        trackerViewController.delegateStatistic = statisticsViewModel
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
            )
        ]
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
}
