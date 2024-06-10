//
//  StatsViewModel.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 08.06.2024.
//

import Foundation

// MARK: - Protocol

protocol StatisticViewControllerProtocol: AnyObject {
    var completedTrackers: [TrackerRecord] { get set }
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
}

// MARK: - CoreData

extension StatsViewModel {
    func fetchStatistics() throws {
        do {
            completedTrackers = try trackerRecordStore.fetchRecords()
            getStatisticsCalculation()
        } catch {
            throw StorageError.failedReading
        }
    }
}

// MARK: - LogicStatistics

extension StatsViewModel {
    private func getStatisticsCalculation() {
        if completedTrackers.isEmpty {
            statistics.removeAll()
        } else {
            statistics = [
                .init(title: NSLocalizedString("bestPeriod", comment: "bestPeriod"), value: "\(bestPeriod())"),
                .init(title: NSLocalizedString("idealDays", comment: "idealDays"), value: "\(idealDays())"),
                .init(title: NSLocalizedString("trackersCompletedStats", comment: "trackersCompletedStats"), value: "\(trackersCompleted())"),
                .init(title: NSLocalizedString("averageValue", comment: "averageValue"), value: "\(averageValue())")
            ]
        }
    }
    
    private func bestPeriod() -> Int {
        let countDict = Dictionary(grouping: completedTrackers, by: { $0.id }).mapValues { $0.count }
        guard let maxCount = countDict.values.max() else {
            return 0
        }
        return maxCount
    }
    
    private func idealDays() -> Int {
        return 0
    }
    
    private func trackersCompleted() -> Int {
        return completedTrackers.count
    }
    
    private func averageValue() -> Int {
        return 0
    }
}

// MARK: - TrackerCategoryStoreDelegate

extension StatsViewModel: TrackersRecordStorageDelegate {
    func didUpdateData(in store: TrackersRecordStorage) {
        try? fetchStatistics()
    }
}

