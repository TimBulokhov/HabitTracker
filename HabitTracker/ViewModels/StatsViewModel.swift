//
//  StatsViewModel.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 08.06.2024.
//

import Foundation
import UIKit
import CoreData

// MARK: - Protocol

protocol StatisticViewControllerProtocol: AnyObject {
    var completedTrackers: [TrackerRecord] { get set }
    func fetchStatistics() throws
}

// MARK: - UIViewController

final class StatsViewModel: StatisticViewControllerProtocol {
    @ObservableValue var completedTrackers: [TrackerRecord] = [] {
        didSet {
            getStatisticsCalculation()
        }
    }
    var statistics: [StatisticsModel] = []
    private let trackerRecordStore = TrackersRecordStorage()
    private let trackerStore = TrackersStorage()
    private let categoryStore = TrackersCategoryStorage()
    private var allTrackers: [Tracker] = []
}

// MARK: - CoreData

extension StatsViewModel {
    func fetchStatistics() throws {
        do {
            completedTrackers = try trackerRecordStore.fetchRecords()
            allTrackers = try trackerStore.fetchTrackers()
            getStatisticsCalculation()
        } catch {
            throw StorageError.failedReading
        }
    }
}

// MARK: - LogicStatistics

extension StatsViewModel {
    private func getStatisticsCalculation() {
        statistics = [
            .init(title: NSLocalizedString("totalProjects", comment: "totalProjects"), value: "\(totalProjects())"),
            .init(title: NSLocalizedString("totalTasks", comment: "totalTasks"), value: "\(totalTasks())"),
            .init(title: NSLocalizedString("totalEvents", comment: "totalEvents"), value: "\(totalEvents())"),
            .init(title: NSLocalizedString("completedTasks", comment: "completedTasks"), value: "\(completedTasks())"),
            .init(title: NSLocalizedString("completedEvents", comment: "completedEvents"), value: "\(completedEvents())"),
            .init(title: NSLocalizedString("completionRate", comment: "completionRate"), value: "\(completionRate())%"),
            .init(title: NSLocalizedString("overdueTasks", comment: "overdueTasks"), value: "\(overdueTasks())")
        ]
    }
    
    private func totalProjects() -> Int {
        do {
            let categories = try categoryStore.fetchAllCategories()
            return categories.count
        } catch {
            return 0
        }
    }
    
    private func totalTasks() -> Int {
        // Считаем количество задач (трекеров с isIrregular = false)
        return allTrackers.filter { !$0.isIrregular }.count
    }
    
    private func totalEvents() -> Int {
        // Считаем количество событий (трекеров с isIrregular = true)
        return allTrackers.filter { $0.isIrregular }.count
    }
    
    private func completedTasks() -> Int {
        // Считаем количество завершенных задач (с учетом статуса done)
        return allTrackers.filter { tracker in
            !tracker.isIrregular && // Это задача
            (tracker.status == "done" || // Либо статус done
             completedTrackers.contains { $0.id == tracker.id }) // Либо есть запись о выполнении
        }.count
    }
    
    private func completedEvents() -> Int {
        // Считаем количество завершенных событий
        return allTrackers.filter { tracker in
            tracker.isIrregular && // Это событие
            tracker.deadline != nil && // Есть дедлайн
            tracker.deadline! < Date() // Дедлайн прошел
        }.count
    }
    
    private func completionRate() -> Int {
        let totalTasks = totalTasks()
        guard totalTasks > 0 else { return 0 }
        let completedTasks = completedTasks()
        return Int((Double(completedTasks) / Double(totalTasks)) * 100)
    }
    
    private func overdueTasks() -> Int {
        let currentDate = Date()
        let completedTaskIds = Set(completedTrackers.map { $0.id })
        
        return allTrackers.filter { tracker in
            !tracker.isIrregular && // Это задача
            tracker.deadline != nil && // Есть дедлайн
            tracker.deadline! < currentDate && // Дедлайн просрочен
            tracker.status != "done" && // Статус не done
            !completedTaskIds.contains(tracker.id) // Нет записи о выполнении
        }.count
    }
}

// MARK: - TrackerCategoryStoreDelegate

extension StatsViewModel: TrackersRecordStorageDelegate {
    func didUpdateData(in store: TrackersRecordStorage) {
        try? fetchStatistics()
    }
}

