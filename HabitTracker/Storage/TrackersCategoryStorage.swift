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
            throw StorageError.failedActoionDelete
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
        return TrackerCategory(title: title, trackers: trackers.compactMap { coreDataTracker -> Tracker? in
            if let coreDataTracker = coreDataTracker as? TrackerCoreData {
                return try? trackerStore.decodingTrackers(from: coreDataTracker)
            }
            return nil
        })
    }
    
    func createCategoryAndTracker(tracker: Tracker, with titleCategory: String) throws {
        guard let trackerCoreData = try trackerStore.addNewTracker(from: tracker) else {
            throw StorageError.failedToWrite
        }
        guard let existingCategory = try fetchCategory(with: titleCategory) else {
            throw StorageError.failedReading
        }
        var existingTrackers = existingCategory.trackers?.allObjects as? [TrackerCoreData] ?? []
        existingTrackers.append(trackerCoreData)
        existingCategory.trackers = NSSet(array: existingTrackers)
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
