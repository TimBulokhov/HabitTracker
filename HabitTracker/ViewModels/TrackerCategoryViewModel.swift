//
//  TrackerCategoryViewModel.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 01.06.2024.
//

import Foundation

// MARK: - CategoryViewModel

final class TrackerCategoryViewModel {
    @ObservableValue private(set) var categories: [TrackerCategory] = []
    
    weak var delegateHabbit: NewHabitViewControllerDelegate?
    weak var delegateIrregular: NewSingleHabitViewControllerDelegate?
    private let dataSorege = DataStorege.shared
    private let trackerCategoryStore = TrackersCategoryStorage()
    
    func categoriesCount() -> Int {
        return categories.count
    }
    
    func addingCategoryToCreate(_ indexPath: IndexPath){
        let nameCategory = categories[indexPath.row].title
        delegateIrregular?.updateSubitle(nameSubitle: nameCategory)
        delegateHabbit?.updateSubitle(nameSubitle: nameCategory)
    }
    
    func selectedCategoryForCheckmark(_ indexPath: IndexPath) {
        dataSorege.saveIndexPathForCheckmark(indexPath)
    }
    
    func loadIndexPathForCheckmark() -> IndexPath? {
        return dataSorege.loadIndexPathForCheckmark()
    }
}

// MARK: - CategoryStoreCoreDate

extension TrackerCategoryViewModel {
    func fetchACategory() throws {
        do {
            let coreDataCategories = try trackerCategoryStore.fetchAllCategories()
            categories = try coreDataCategories.compactMap { coreDataCategory in
                return try trackerCategoryStore.decodingCategory(from: coreDataCategory)
            }
        } catch {
            throw StorageError.failedReading
        }
    }
    
    func createACategory(nameOfCategory: String) throws {
        do {
            let newCategory = TrackerCategory(title: nameOfCategory, trackers: [])
            try trackerCategoryStore.createCategory(newCategory)
        } catch {
            throw StorageError.failedToWrite
        }
    }
    
    func removeACategory(atIndex index: Int) throws {
        let nameOfCategory = categories[index].title
        do {
            try trackerCategoryStore.deleteCategory(with: nameOfCategory)
            try fetchACategory()
        } catch {
            throw StorageError.failedActionDelete
        }
    }
}

// MARK: - TrackerStoreDelegate

extension TrackerCategoryViewModel: TrackersCategoryStorageDelegate {
    func didUpdateData(in store: TrackersCategoryStorage) {
        try? fetchACategory()
    }
}

