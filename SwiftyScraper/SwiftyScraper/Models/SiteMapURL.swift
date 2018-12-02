//
//  SiteMapURL.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 21/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Sitemap webpage entry. */
public struct SiteMapURL {
    
    /** URL of a web page. */
    public let url: URL
    /** Last updated. */
    public let lastUpdated: Date
    /** Priority. */
    public let priority: Float
    
}
