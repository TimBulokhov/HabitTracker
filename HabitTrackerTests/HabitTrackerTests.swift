//
//  HabitTrackerTests.swift
//  HabitTrackerTests
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import XCTest
import SnapshotTesting
@testable import HabitTracker

final class HabitTrackerTests: XCTestCase {
    
    func testTabBarController() {
        let viewController = TabBarController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
    
    func testTrackersViewController() {
        let viewController = TrackersViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
    
    func testStatisticsViewController() {
        let viewController = StatisticsViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
        
    }
    
    func testFilterViewController() {
        let viewController = FilterViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
    
    func testNewTrackerViewController() {
        let viewController = NewTrackerViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
    
    func testNewHabitViewController() {
        let viewController = NewHabitViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
    
    func testNewSingleHabitViewController() {
        let viewController = NewSingleHabitViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
    
    func testTrackerCategoryViewController() {
        let viewController = TrackerCategoryViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
    
    func testCreatingCategoryViewController() {
        let viewController = CreatingCategoryViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
    
    func testScheduleViewController() {
        let viewController = ScheduleViewController()
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)))
        assertSnapshot(of: viewController, as: .image(traits: UITraitCollection(userInterfaceStyle: .light)))
    }
}
