//
//  ScraperType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Describes a scraper that parses info from a response.
 */
public protocol ScraperType {
    
    /** Entity to parse. */
    associatedtype Entity
    
    /** Content type that this scraper expects. For all content types return `nil`. */
    var contentType: String? { get }
    /** URL regex for which this scraper is customized for. For all URLs return `nil`. */
    var urlTemplate: String? { get }
    
    /** Extracts info from given response data. */
    func scrape(response: HTTPURLResponse, data: Data, callback: @escaping (Result<Entity>) -> Void)
    
}
