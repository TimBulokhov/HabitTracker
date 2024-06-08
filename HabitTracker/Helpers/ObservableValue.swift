//
//  ObservableValue.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 01.06.2024.
//

import Foundation

@propertyWrapper
final class ObservableValue<T> {
    typealias TypeValue = T
    
    private var onChange: ((TypeValue) -> Void)?
    
    var wrappedValue: TypeValue {
        didSet {
            onChange?(wrappedValue)
        }
    }
    
    var projectedValue: ObservableValue<T> {
        return self
    }
    
    // MARK: - Initialisation
    
    init(wrappedValue: TypeValue) {
        onChange = nil
        self.wrappedValue = wrappedValue
    }
    
    // MARK: - Methods
    
    func bind(action: @escaping (TypeValue) -> Void) {
        self.onChange = action
    }
}

