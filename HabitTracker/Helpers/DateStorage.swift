//
//  DateStorage.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import Foundation

final class DataStorege {
    static let shared = DataStorege()
    private let defaults = UserDefaults.standard
    private let categoryKey = "CategoryKey"
    private let indexPathForCheckmark = "IndexPathForCheckmark"
    private let daysInAWeek = "DaysInAWeek"
    private let trackerKey = "TrackerKey"
    private let firstLaunchKey = "firstLaunchApplication"
    
    var firstLaunchApplication: Bool {
        get {
            return defaults.value(forKey: firstLaunchKey) as? Bool ?? false
        }
        set {
            defaults.set(newValue, forKey: firstLaunchKey)
        }
    }
}

// MARK: - CategoryViewController

extension DataStorege {
    func saveIndexPathForCheckmark(_ indexPath: IndexPath) {
        let selectedRow = indexPath.row
        defaults.set(selectedRow, forKey: indexPathForCheckmark)
        defaults.synchronize()
    }
    
    func loadIndexPathForCheckmark() -> IndexPath? {
        guard let selectedRow = defaults.value(forKey: indexPathForCheckmark) as? Int else {
            return nil
        }
        
        return IndexPath(row: selectedRow, section: 0)
    }
    
    func removeIndexPathForCheckmark() {
        defaults.removeObject(forKey: indexPathForCheckmark)
        defaults.synchronize()
    }
}

// MARK: - ScheduleViewController

extension DataStorege {
    func saveDaysInAWeek(_ days: String) {
        let day = [days]
        var existingDaysInAWeek = loadDaysInAWeek()
        existingDaysInAWeek.append(contentsOf: day)
        defaults.set(existingDaysInAWeek, forKey: daysInAWeek)
        defaults.synchronize()
    }
    
    func loadDaysInAWeek() -> [String] {
        return defaults.array(forKey: daysInAWeek) as? [String] ?? []
    }
    
    func removeDaysInAWeek(atIndex index: Int) {
        var existingCategories = loadDaysInAWeek()
        existingCategories.remove(at: index)
        defaults.set(existingCategories, forKey: daysInAWeek)
    }
    
    func removeAllDaysInAWeek() {
        defaults.removeObject(forKey: daysInAWeek)
        defaults.synchronize()
    }
}
