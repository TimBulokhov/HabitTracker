//
//  TrackersStorage.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 25.05.2024.
//

import UIKit
import CoreData

final class TrackersStorage {
    private let context: NSManagedObjectContext
    
    // MARK: - Initialisation
    
    convenience init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.init(context: context)
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Methods
    
    func addNewTracker(from tracker: Tracker) throws -> TrackerCoreData? {
        guard let trackerCoreData = NSEntityDescription.entity(forEntityName: "TrackerCoreData", in: context) else {
            throw StorageError.failedToWrite
        }
        let newTracker = TrackerCoreData(entity: trackerCoreData, insertInto: context)
        newTracker.id = tracker.id
        newTracker.name = tracker.name
        newTracker.color = UIColorSorting.hexString(from: tracker.color)
        newTracker.emoji = tracker.emoji
        newTracker.isPinned = tracker.isPinned
        newTracker.pinDate = tracker.pinDate
        newTracker.createdAt = tracker.createdAt ?? Date()
        newTracker.deadline = tracker.deadline
        return newTracker
    }
    
    func fetchTrackers() throws -> [Tracker] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw StorageError.failedReading
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        
        do {
            let trackerCoreDataArray = try managedContext.fetch(fetchRequest)
            // Автозаполнение pinDate для закреплённых трекеров без даты
            var needSave = false
            for trackerCoreData in trackerCoreDataArray {
                if trackerCoreData.isPinned && trackerCoreData.pinDate == nil {
                    trackerCoreData.pinDate = Date()
                    needSave = true
                }
            }
            if needSave {
                try managedContext.save()
            }
            let trackers = trackerCoreDataArray.map { trackerCoreData in
                return Tracker(
                    id: trackerCoreData.id ?? UUID(),
                    name: trackerCoreData.name ?? "",
                    color: UIColorSorting.color(from: trackerCoreData.color ?? ""),
                    emoji: trackerCoreData.emoji ?? "",
                    isPinned: trackerCoreData.isPinned,
                    pinDate: trackerCoreData.pinDate,
                    createdAt: trackerCoreData.createdAt,
                    deadline: trackerCoreData.deadline,
                    isIrregular: false
                )
            }
            return trackers
        } catch {
            throw StorageError.failedReading
        }
    }
    
    func decodingTrackers(from trackersCoreData: TrackerCoreData) throws -> Tracker {
        guard let id = trackersCoreData.id,
              let name = trackersCoreData.name,
              let color = trackersCoreData.color,
              let emoji = trackersCoreData.emoji
        else {
            throw StorageError.failedDecoding
        }
        return Tracker(
            id: id,
            name: name,
            color: UIColorSorting.color(from: color),
            emoji: emoji,
            isPinned: trackersCoreData.isPinned,
            pinDate: trackersCoreData.pinDate,
            createdAt: trackersCoreData.createdAt,
            deadline: trackersCoreData.deadline,
            isIrregular: false
        )
    }
    
    func deleteTrackers(tracker: Tracker) throws {
        let fetchRequest = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        do {
            let tracker = try context.fetch(fetchRequest)
            
            if let trackerToDelete = tracker.first {
                context.delete(trackerToDelete)
                try context.save()
            } else {
                throw StorageError.failedGettingTitle
            }
        } catch {
            throw StorageError.failedActionDelete
        }
    }
    
    func updateTracker(with tracker: Tracker) throws {
        let fetchRequest = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        do {
            let existingTrackers = try context.fetch(fetchRequest)
            
            if let existingTracker = existingTrackers.first {
                existingTracker.name = tracker.name
                existingTracker.color = UIColorSorting.hexString(from: tracker.color)
                existingTracker.emoji = tracker.emoji
                existingTracker.isPinned = tracker.isPinned
                existingTracker.pinDate = tracker.pinDate
                if let createdAt = tracker.createdAt {
                    existingTracker.createdAt = createdAt
                }
                existingTracker.deadline = tracker.deadline
                try context.save()
            } else {
                throw StorageError.trackerNotFound
            }
        } catch {
            throw StorageError.failedActionUpdate
        }
    }
}


