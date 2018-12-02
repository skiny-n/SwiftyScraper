//
//  AnyScraper.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Type eraser for scrapers.
 */
public final class AnyScraper<Resource>: ScraperType {
    
    public typealias Entity = Resource
    
    public let contentType: String?
    public let urlTemplate: String?
    
    private let _scrape: (HTTPURLResponse, Data, @escaping (Result<Entity>) -> Void) -> Void
    
    public init<T: ScraperType>(_ scraper: T) where T.Entity == Resource {
        self.contentType = scraper.contentType
        self.urlTemplate = scraper.urlTemplate
        self._scrape = scraper.scrape
    }
    
    public func scrape(response: HTTPURLResponse, data: Data, callback: @escaping (Result<Resource>) -> Void) {
        _scrape(response, data, callback)
    }
    
}
