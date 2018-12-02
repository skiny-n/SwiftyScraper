//
//  WeatherFetcher.swift
//  WeatherFetcher
//
//  Created by Stanislav Novacek on 25/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import SwiftyScraper

/**
 The main scraper class.
 */
class WeatherFetcher: SwiftyScraper {
    
    /** Initializes a new instance with given city name, scraping configuration, URL frontier and a pipeline router. */
    convenience init(city: String, configuration: ScrapingConfiguration, urlFrontier: FrontierCoordinatorType, pipelineRouter: PipelineRouter) {
        // Construct search URL to get a city identifier
        let sanitizedCityName = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let url = "https://weather.codes/search/?q=\(sanitizedCityName)"
        self.init(startURLs: [url], configuration: configuration, urlFrontier: urlFrontier, pipelineRouter: pipelineRouter)
        // Don't use host filtering since we're jumping between 2 hosts
        self.useHostFilter = false
    }
    
}
