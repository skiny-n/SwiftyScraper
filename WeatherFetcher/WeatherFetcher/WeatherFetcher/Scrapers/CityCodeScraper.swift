//
//  CityCodeScraper.swift
//  WeatherFetcher
//
//  Created by Stanislav Novacek on 25/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import SwiftyScraper
import SwiftSoup


/** Scraper that extracts city codes used for weather.com website. */
class CityCodeScraper: ScraperType {
    
    typealias Entity = [URLEntry]
    
    var contentType: String? = nil
    var urlTemplate: String? = "(?:http|https):\\/\\/weather\\.codes\\/search\\/\\?q="
    
    func scrape(response: HTTPURLResponse, data: Data, callback: @escaping (Result<[URLEntry]>) -> Void) {
        do {
            // Try parsing the HTML
            let htmlString = String(data: data, encoding: .utf8) ?? ""
            let html = try SwiftSoup.parse(htmlString)
            
            // Extract city codes and city names
            let cityCodes = try html.select("div.section__content > dl > dt").map({ try $0.text() })
            let cityNames = try html.select("div.section__content > dl > dd").map({ try $0.text() })
            
            // Helper block for error cases
            let errorCallback = {
                Log.warning { Log.message("Empty city codes search") }
                print("Empty city codes search - could not find any related city, please check the name or use another closer to this one.")
                callback(.error(.empty))
            }
            
            // Check for emty search
            if cityCodes.isEmpty {
                return errorCallback()
            }
            
            // Only 1 city found -> continue
            if cityCodes.count == 1 {
                if let cityCode = cityCodes.first, let cityName = cityNames.first, let entry = URLEntry(urlString: "https://weather.com/weather/hourbyhour/l/\(cityCode)") {
                    Log.info { Log.message("Found code \(cityCode) for city \(cityName) -> scraping weather info...") }
                    print("Found code \(cityCode) for city \(cityName) -> scraping weather info...")
                    return callback(.success([entry]))
                } else {
                    return errorCallback()
                }
            }
            
            // More than 1 search result -> let the user choose
            askForSelection(withCodes: cityCodes, names: cityNames, callback: callback)
            
        } catch {
            // Error parsing the HTML
            Log.error { Log.message("Could not parse HTML from \(response.url?.absoluteString ?? "-unknown URL-")") }
            print("Error: Could not parse HTML from \(response.url?.absoluteString ?? "-unknown URL-")")
            print("Error occured - please see the logs at ./logs/")
            return callback(.error(.parsing(error)))
        }
        
    }
    
    // MARK: Private
    
    /** Asks the user to select from given search results. */
    private func askForSelection(withCodes codes: [String], names: [String], callback: @escaping (Result<[URLEntry]>) -> Void) {
        // Print the choices
        var selectionLines: [String] = []
        for (i, (_, name)) in zip(codes, names).enumerated() {
            selectionLines.append("[\(i)] \(name)")
        }
        print("Found these cities:")
        print(selectionLines.joined(separator: "\n"))
        // Ask for a specific line
        askForSelection(withLines: selectionLines) { (index) in
            if (0..<codes.count).contains(index) && (0..<names.count).contains(index) {
                // Valid index
                let code = codes[index]
                let name = names[index]
                if let entry = URLEntry(urlString: "https://weather.com/weather/hourbyhour/l/\(code)") {
                    Log.info { Log.message("Found code \(code) for city \(name) -> scraping weather info...") }
                    print("Found code \(code) for city \(name) -> scraping weather info...")
                    return callback(.success([entry]))
                }
            }
            // Invalid index
            Log.error { Log.message("Error while selecting a city") }
            print("Error: error while selecting a city")
            callback(.error(.empty))
        }
    }
    
    /** Asks the user to select a specific line from given lines. */
    private func askForSelection(withLines lines: [String], callback: @escaping (Int) -> Void) {
        print("Choose by typing a number of your choice:")
        if let result = readLine(strippingNewline: true), let index = Int(result), index >= 0 && index < lines.count {
            callback(index)
        } else {
            askForSelection(withLines: lines, callback: callback)
        }
    }
    
}
