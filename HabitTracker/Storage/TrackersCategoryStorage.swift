//
//  TrackersCategoryStorage.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 25.05.2024.
//

import UIKit
import CoreData

protocol TrackersCategoryStorageDelegate: AnyObject {
    func didUpdateData(in store: TrackersCategoryStorage)
}

// MARK: - TrackerCategoryStore

final class TrackersCategoryStorage: NSObject {
    weak var delegate: TrackersCategoryStorageDelegate?
    private let context: NSManagedObjectContext
    private let trackerStore = TrackersStorage()
    private lazy var fetchedResultController: NSFetchedResultsController<TrackerCategoryCoreData>! = {
        let request = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        let sortDescriptor = NSSortDescriptor(keyPath: \TrackerCategoryCoreData.titleCategory, ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        try? controller.performFetch()
        return controller
    }()
    
    // MARK: Initialisation
    convenience override init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.init(context: context)
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

// MARK: - Category management

extension TrackersCategoryStorage {
    
    // MARK: - Methods
    
    func createCategory(_ category: TrackerCategory) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: "TrackerCategoryCoreData", in: context) else {
            throw StorageError.failedToWrite
        }
        let categoryEntity = TrackerCategoryCoreData(entity: entity, insertInto: context)
        categoryEntity.titleCategory = category.title
        categoryEntity.trackers = NSSet(array: [])
        try context.save()
    }
    
    func fetchAllCategories() throws -> [TrackerCategoryCoreData] {
        return try context.fetch(NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData"))
    }
    
    func deleteCategory(with title: String) throws {
        let request = fetchedResultController.fetchRequest
        request.predicate = NSPredicate(format: "%K == %@", "titleCategory", title)
        do {
            let categories = try context.fetch(request)
            if let categoryToDelete = categories.first {
                context.delete(categoryToDelete)
                try context.save()
            } else {
                throw StorageError.failedGettingTitle
            }
        } catch {
            throw StorageError.failedActionDelete
        }
    }
}

// MARK: - Creating trackers in categories

extension TrackersCategoryStorage {
    
    //MARK: - Methods
    
    func decodingCategory(from trackerCategoryCoreData: TrackerCategoryCoreData) throws -> TrackerCategory? {
        guard let title = trackerCategoryCoreData.titleCategory else {
            throw StorageError.failedReading
        }
        guard let trackers = trackerCategoryCoreData.trackers else {
            throw StorageError.failedReading
        }
        let trackerList: [Tracker] = trackers.compactMap { coreDataTracker in
            guard let coreDataTracker = coreDataTracker as? TrackerCoreData else { return nil }
                return try? trackerStore.decodingTrackers(from: coreDataTracker)
            }
        return TrackerCategory(title: title, trackers: trackerList)
    }
    
    func createCategoryAndTracker(tracker: Tracker, with titleCategory: String) throws {
        // Проверяем, есть ли уже трекер с таким id в базе
        let fetchRequest = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        let found = try context.fetch(fetchRequest)
        let trackerCoreData: TrackerCoreData
        if let existing = found.first {
            trackerCoreData = existing
        } else {
            guard let created = try trackerStore.addNewTracker(from: tracker) else {
            throw StorageError.failedToWrite
            }
            trackerCoreData = created
        }
        guard let existingCategory = try fetchCategory(with: titleCategory) else {
            throw StorageError.failedReading
        }
        var existingTrackers = existingCategory.trackers?.allObjects as? [TrackerCoreData] ?? []
        // Удаляем дубликаты по id
        existingTrackers.removeAll { $0.id == tracker.id }
        existingTrackers.append(trackerCoreData)
        existingCategory.trackers = NSSet(array: existingTrackers)
        try context.save()
    }
    
    // Перенос трекера между категориями
    func moveTracker(_ tracker: Tracker, toCategory newCategory: String, fromCategory oldCategory: String) throws {
        // Найти старую категорию
        guard let oldCategoryCoreData = try fetchCategory(with: oldCategory) else {
            throw StorageError.failedReading
        }
        // Найти новую категорию
        guard let newCategoryCoreData = try fetchCategory(with: newCategory) else {
            throw StorageError.failedReading
        }
        // Найти трекер в базе по id
        let fetchRequest = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        let found = try context.fetch(fetchRequest)
        guard let trackerCoreData = found.first else {
            throw StorageError.trackerNotFound
        }
        // Удалить из старой категории
        var oldTrackers = oldCategoryCoreData.trackers?.allObjects as? [TrackerCoreData] ?? []
        oldTrackers.removeAll { $0.id == tracker.id }
        oldCategoryCoreData.trackers = NSSet(array: oldTrackers)
        // Добавить в новую категорию (без дубликатов)
        var newTrackers = newCategoryCoreData.trackers?.allObjects as? [TrackerCoreData] ?? []
        newTrackers.removeAll { $0.id == tracker.id }
        // Обновить дату перемещения
        trackerCoreData.createdAt = Date()
        newTrackers.append(trackerCoreData)
        newCategoryCoreData.trackers = NSSet(array: newTrackers)
        try context.save()
    }
    
    //MARK: - Private methods
    
    private func fetchCategory(with title: String) throws -> TrackerCategoryCoreData? {
        let request = fetchedResultController.fetchRequest
        request.predicate = NSPredicate(format: "titleCategory == %@", title)
        return try context.fetch(request).first
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackersCategoryStorage: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateData(in: self)
    }
}
