//
//  SiteMap.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 21/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/** Represents a sitemap. */
public struct SiteMap {
    
    /** URL. */
    public let url: URL
    /** Last updated. */
    public let lastUpdated: Date?
    /** Sitemap entries. */
    public let entries: [SiteMapURL]
    
}
