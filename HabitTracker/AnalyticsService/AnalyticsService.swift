//
//  AnalyticsService.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 09.06.2024.
//

import Foundation
import AppMetricaCore

struct AnalyticsService {
    static func activate() {
        guard let configuration = AppMetricaConfiguration(apiKey: "ec881823-18f9-4d2b-8122-140e9a687035") else { return }
        
        AppMetrica.activate(with: configuration)
    }
    
    func report(event: Events, params : [AnyHashable : Any]) {
        AppMetrica.reportEvent(name: event.rawValue, parameters: params, onFailure: { error in
            print("REPORT ERROR: %@", error.localizedDescription)
        })
    }
}
