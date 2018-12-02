//
//  RobotsFilter.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Robots.txt filer helper. */
public struct RobotsFilter {
    
    /** Filter entries. */
    public let entries: [RobotsFilterEntry]
    
    /** Whether given URL is allowed to crawl for given user agent. */
    public func isAllowed(url: String, forAgent agent: String) -> Bool {
        // Get valid user agents - the last one according to overrides in robots.txt
        if let entryForAget = entries.filter({ agent.matchesRegex($0.userAgent) }).last {
            // Check for disallows
            var isAllowed = true
            if let _ = entryForAget.disallow.first(where: { url.matchesRegex($0) }) {
                // Found disallowed template
                isAllowed = false
            }
            // chack for explicit allow template
            if isAllowed == false, let _ = entryForAget.allow.first(where: { url.matchesRegex($0) }) {
                isAllowed = true
            }
            if isAllowed == false {
                Log.warning { Log.message("Robots filter: \(agent) not allowed to crawl \(url)") }
            }
            return isAllowed
        }
        // Nothing -> allow
        return true
    }
    
}
