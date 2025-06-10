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
        newTracker.dateEvents = (tracker.dateEvents ?? []) as NSArray
        newTracker.isPinned = tracker.isPinned
        newTracker.pinDate = tracker.pinDate
        newTracker.createdAt = tracker.createdAt ?? Date()
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
                    dateEvents: trackerCoreData.dateEvents as? [Int],
                    isPinned: trackerCoreData.isPinned,
                    pinDate: trackerCoreData.pinDate,
                    createdAt: trackerCoreData.createdAt
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
        let rawDateEvents = trackersCoreData.dateEvents as? [Int]
        let dateEvents = (rawDateEvents?.isEmpty == true) ? nil : rawDateEvents
        return Tracker(
            id: id,
            name: name,
            color: UIColorSorting.color(from: color),
            emoji: emoji,
            dateEvents: dateEvents,
            isPinned: trackersCoreData.isPinned,
            pinDate: trackersCoreData.pinDate,
            createdAt: trackersCoreData.createdAt
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
                existingTracker.dateEvents = (tracker.dateEvents ?? []) as NSArray
                existingTracker.isPinned = tracker.isPinned
                existingTracker.pinDate = tracker.pinDate
                if let createdAt = tracker.createdAt {
                    existingTracker.createdAt = createdAt
                }
                try context.save()
            } else {
                throw StorageError.trackerNotFound
            }
        } catch {
            throw StorageError.failedActionUpdate
        }
    }
}


