//
//  TabBarController.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

final class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let trackerViewController = TrackersViewController()
        trackerViewController.tabBarItem = UITabBarItem(
            title: "Trackers",
            image: UIImage(named: "trackersIcon"),
            selectedImage: UIImage(named: "trackersIcon")
        )
        
        let statsViewController = StatsViewController()
        statsViewController.tabBarItem = UITabBarItem(
            title: "Statistic",
            image: UIImage(named: "statsIcon"),
            selectedImage: UIImage(named: "statsIcon")
        )
        
        viewControllers = [createNavigationController(rootViewController: trackerViewController),
                           createNavigationController(rootViewController: statsViewController)
        ]
        
        let separatorTabBarLine = UIView()
        separatorTabBarLine.backgroundColor = .ypGray
        separatorTabBarLine.translatesAutoresizingMaskIntoConstraints = false
        
        tabBar.addSubview(separatorTabBarLine)
        
        NSLayoutConstraint.activate([
            separatorTabBarLine.topAnchor.constraint(equalTo: tabBar.topAnchor),
            separatorTabBarLine.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            separatorTabBarLine.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            separatorTabBarLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        
    }
    
    private func createNavigationController(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        return navigationController
    }
}
