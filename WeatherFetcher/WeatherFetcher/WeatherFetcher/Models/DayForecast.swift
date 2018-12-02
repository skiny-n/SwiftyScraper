//
//  DayForecast.swift
//  WeatherFetcher
//
//  Created by Stanislav Novacek on 25/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import SwiftyScraper


/**
 A struct wrapping a forecast info.
 */
struct DayForecast {
    
    /** JSON keys. */
    private enum Keys {
        static let feelsLike = "feelsLike"
        static let windSpeed = "windSpeed"
        static let windDirCompass = "windDirCompass"
        static let temperature = "temperature"
        static let rh = "rh"
        static let phrase = "phrase"
        static let precipPct = "precipPct"
        static let processTime = "processTime"
    }
    
    /** Date formatter for parsing timestamps. */
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    /** Date formatter for output date. */
    private static let outputDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm EEE (dd. MMM)"
        return f
    }()
    
    /** Timestamp. */
    let timestamp: String
    /** Temperature. */
    let temperature: Double
    /** Feels like temperature. */
    let feelsLike: Double
    /** Human readable phrase. */
    let phrase: String
    /** Precipitation. */
    let precipPerc: Double
    /** Humidity. */
    let humidityPerc: Double
    /** Wind speed. */
    let windSpeed: Double
    /** Wind direction. */
    let windDirection: String
    
    // Computed
    
    /** Date computed from `timestamp` */
    let date: Date
    /** Human readable formatted date. */
    let outputDate: String
    
    /** Initializes a new instance from given `JSON`. Returns `nil` for invalid payloads. */
    init?(json: JSON) {
        if let ts = json[Keys.processTime] as? String,
            let temp = json[Keys.temperature] as? Double,
            let feels = json[Keys.feelsLike] as? Double,
            let phrase = json[Keys.phrase] as? String,
            let precip = json[Keys.precipPct] as? Double,
            let humid = json[Keys.rh] as? Double,
            let windSpeed = json[Keys.windSpeed] as? Double,
            let windDir = json[Keys.windDirCompass] as? String,
            let date = DayForecast.dateFormatter.date(from: ts)
        {
            self.timestamp = ts
            self.temperature = temp
            self.feelsLike = feels
            self.phrase = phrase
            self.precipPerc = precip
            self.humidityPerc = humid
            self.windSpeed = windSpeed
            self.windDirection = windDir
            self.date = date
            self.outputDate = DayForecast.outputDateFormatter.string(from: date)
        } else {
            // Invalid payload
            return nil
        }
    }
    
}
