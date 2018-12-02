//
//  RobotsFilterEntry.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 21/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Represents an entry in robots.txt file. */
public struct RobotsFilterEntry {
    
    /** User agent this entry is for. */
    public let userAgent: String
    /** Crawl delay. */
    public let crawlDelay: TimeInterval
    /** Allowed paths. */
    public let allow: [String]
    /** Disallowed paths. */
    public let disallow: [String]
    
}
