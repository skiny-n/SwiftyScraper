//
//  ForecastUnits.swift
//  WeatherFetcher
//
//  Created by Stanislav Novacek on 25/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import SwiftyScraper

/**
 A struct representing unit settings from fetched forecasts.
 */
struct ForecastUnits {
    
    /// Unit for temperature.
    let temperature: String
    /// Unit for speed.
    let speed: String
    /// Unit for percents.
    let percent: String
    
    /** Initializes a new instance with given `JSON`. Returns `nil` if the `JSON` is invalid. */
    init?(json: JSON) {
        if let temp = json["temp"] as? String,
            let speed = json["speed"] as? String
        {
            self.temperature = temp
            self.speed = speed
            self.percent = "%"
        } else {
            return nil
        }
    }
    
}
