//
//  HourlyForecastScraper.swift
//  WeatherFetcher
//
//  Created by Stanislav Novacek on 25/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import SwiftyScraper
import SwiftSoup

/**
 Scraper that exctracts weather forecast from weather.com hourly forecast.
 */
class HourlyForecastScraper: ScraperType {
    
    typealias Entity = [HourlyForecastScraperEntity]
    
    var contentType: String? = nil
    var urlTemplate: String? = "(?:http|https):\\/\\/weather.com\\/weather\\/hourbyhour"
    
    func scrape(response: HTTPURLResponse, data: Data, callback: @escaping (Result<[HourlyForecastScraperEntity]>) -> Void) {
        do {
            // Try parsing the HTML
            let htmlString = String(data: data, encoding: .utf8) ?? ""
            let html = try SwiftSoup.parse(htmlString)
            // Select all `script` tags
            let scripts = try html.select("script")
            // Find the one with data payload
            let scriptDataString = try scripts.array().first(where: { e in try e.html().hasPrefix("window.__data") })?.html()
            if let scriptDataString = scriptDataString,
                let firstCurlyPosition = scriptDataString.firstIndex(of: "{"),
                let windowPosition = scriptDataString.range(of: ";window")
            {
                // Try parsing the data payload
                let jsonString = scriptDataString.prefix(upTo: windowPosition.lowerBound).suffix(from: firstCurlyPosition)
                if let data = jsonString.data(using: .utf8),
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                {
                    // Find the forecast info and parse it
                    let hourlyJSON = (json["dal"] as? JSON)?["HourlyForecast"] as? JSON
                    let unitsJSON = json["unitOfMeasurement"] as? JSON
                    if let hourlyJSON = hourlyJSON, let unitsJSON = unitsJSON,
                        let firstKey = hourlyJSON.keys.first(where: { $0.hasPrefix("geocode") }),
                        let hourJSONs = ((hourlyJSON[firstKey] as? JSON)?["data"] as? JSON)?["vt1hourlyForecast"] as? [JSON],
                        let units = ForecastUnits(json: unitsJSON)
                    {
                        // Create forecasts
                        let forecasts = hourJSONs.compactMap(DayForecast.init)
                        
                        // Print forecast output
                        let output = OutputBuilder.createOutput(from: forecasts, units: units)
                        let message = """
                        Weater forecast:
                        \(output.header)
                        \(output.rows.joined(separator: "\n"))
                        
                        """
                        Log.info { Log.message(message) }
                        print(message)
                        
                        // Done -> exit
                        exit(ExitCodes.finished.rawValue)
                    }
                }
            }
            // Error parsing needed info
            Log.error { Log.message("Could load forecast data from \(response.url?.absoluteString ?? "-unknown URL-")").attachInfo(scriptDataString) }
            print("Error: Could load forecast data from \(response.url?.absoluteString ?? "-unknown URL-"). Data: \(String(describing: scriptDataString))")
            print("Error occured - please see the logs at ./logs/")
            return callback(.error(.parsing("Could load forecast data from \(response.url?.absoluteString ?? "-unknown URL-"). Data: \(String(describing: scriptDataString))")))
        } catch {
            // Error parsing the HTML
            Log.error { Log.message("Could not parse HTML from \(response.url?.absoluteString ?? "-unknown URL-")") }
            print("Error: Could not parse HTML from \(response.url?.absoluteString ?? "-unknown URL-")")
            print("Error occured - please see the logs at ./logs/")
            return callback(.error(.parsing(error)))
        }
    }
    
}
