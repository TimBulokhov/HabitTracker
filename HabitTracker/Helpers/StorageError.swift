//
//  StorageError.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 25.05.2024.
//

import Foundation

enum StorageError: Error {
    case failedToWrite
    case failedReading
    case failedDecoding
    case failedGettingTitle
    case failedActionDelete
    case failedActionUpdate
    case trackerNotFound
}
