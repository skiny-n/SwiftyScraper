//
//  HourlyForecastScraperEntity.swift
//  WeatherFetcher
//
//  Created by Stanislav Novacek on 25/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import SwiftyScraper


/**
 Represents an output entity used by `HourlyForecastScraper`.
 */
struct HourlyForecastScraperEntity {
    
    let identifier: String = UUID().uuidString
    
    /// Forecasts.
    let forecasts: [DayForecast]
    /// Units.
    let units: ForecastUnits
    
}

extension HourlyForecastScraperEntity: IdentifiableType {
    
    static func ==(lhs: HourlyForecastScraperEntity, rhs: HourlyForecastScraperEntity) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}
