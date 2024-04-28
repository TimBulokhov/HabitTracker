//
//  CollectionSetup.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import Foundation

struct CollectionSettings {
    let cellCount: Int
    let topDistance: CGFloat
    let leftDistance: CGFloat
    let rightDistance: CGFloat
    let cellSpacing: CGFloat
    let paddingWidth: CGFloat
    
    init(cellCount: Int, topDistance: CGFloat, leftDistance: CGFloat, rightDistance: CGFloat, cellSpacing: CGFloat) {
        self.cellCount = cellCount
        self.topDistance = topDistance
        self.leftDistance = leftDistance
        self.rightDistance = rightDistance
        self.cellSpacing = cellSpacing
        self.paddingWidth = leftDistance + rightDistance + CGFloat(cellCount - 1) * cellSpacing
    }
}
