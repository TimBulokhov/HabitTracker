//
//  Tracker.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

struct Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let isPinned: Bool
    let createdAt: Date?
    var deadline: Date?
    let isIrregular: Bool
    let status: String
}
