//
//  Tracker.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

enum AttachmentType: String, Codable {
    case photo
    case file
    case link
    case video
    case code
    case other
}

struct Attachment: Codable, Equatable {
    let id: UUID
    let type: AttachmentType
    let url: URL?
    let text: String?
    let fileName: String?
    // Можно добавить другие поля при необходимости
    
    init(type: AttachmentType, url: URL? = nil, text: String? = nil, fileName: String? = nil) {
        self.id = UUID()
        self.type = type
        self.url = url
        self.text = text
        self.fileName = fileName
    }
}

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
    let assignee: String
    let pinnedAt: Date?
    let details: String?
    var attachments: [Attachment]?
}
