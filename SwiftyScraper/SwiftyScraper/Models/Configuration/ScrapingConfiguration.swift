//
//  ScrapingConfiguration.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Scraping engine configuration.
 */
public struct ScrapingConfiguration {
    
    private enum CodingKeys: String {
        
        case workerLimit        = "workerLimit"
        case workerRequestLimit = "workerRequestLimit"
        case depthLimit         = "depthLimit"
        case urlCountLimit      = "urlCountLimit"
        case proxyListPath      = "proxyListPath"
        case userAgentListPath  = "userAgentListPath"
        case refererListPath    = "refererListPath"
        case urlFilter          = "urlFilter"
        case ignoreRobotsTXT    = "ignoreRobotsTXT"
        case ignoreSiteMap      = "ignoreSiteMap"
        case requestDelay       = "requestDelay"
        case requestTimeout     = "requestTimeout"
        case requestThrottling  = "requestThrottling"
        case urlRetriesLimit    = "urlRetriesLimit"
        case authentication     = "authentication"
        case cookies            = "cookies"
        
    }
    
    /** Default configuration. */
    public static var defaultConfiguration: ScrapingConfiguration { return ScrapingConfiguration(json: [:]) }
    
    /** Maximum number of parallel workers. */
    public let workerLimit: Int
    /** Maximum number of requests per worker. */
    public let workerRequestLimit: Int
    /** Crawling depth limit (up -> down). */
    public let depthLimit: Int
    /** Maximum number of crawled URLs (pages, images, etc.). */
    public let urlCountLimit: Int
    /** Path to a file with proxies. */
    public let proxyListPath: String?
    /** Path to a file with user agents. */
    public let userAgentListPath: String?
    /** Path to a file with referrers. */
    public let refererListPath: String?
    /** URL filtering. */
    public var urlFilter: URLFilter
    /** Whether to honor robots.txt */
    public let ignoreRobotsTXT: Bool
    /** Whether to parse and crawl a sitemap (if there's and available). */
    public let ignoreSiteMap: Bool
    /**
     Delay between requests per worker.
     This delay may wary slightly as randomization and throtling are mixed into final value.
     */
    public let requestDelay: TimeInterval
    /** Request timeout. */
    public let requestTimeout: TimeInterval
    /**
     Add a backoff that’s proportional to how long a site took to respond to previous request.
     That way if a site gets overwhelmed and starts to slow down, next requests will automatically back off.
     */
    public let requestThrottling: Bool
    /** Maximum number of single URL retries. */
    public let urlRetriesLimit: Int
    /** Authentication. */
    public let authentication: Authentication?
    /** Cookies to send with every request. */
    public let cookies: String?
    
    /** Internal init. */
    init(json: JSON) {
        self.workerLimit = json[CodingKeys.workerLimit.rawValue] as? Int ?? 5
        self.workerRequestLimit = json[CodingKeys.workerRequestLimit.rawValue] as? Int ?? 10
        self.depthLimit = json[CodingKeys.depthLimit.rawValue] as? Int ?? -1
        self.urlCountLimit = json[CodingKeys.urlCountLimit.rawValue] as? Int ?? -1
        self.proxyListPath = json[CodingKeys.proxyListPath.rawValue] as? String
        self.userAgentListPath = json[CodingKeys.userAgentListPath.rawValue] as? String
        self.refererListPath = json[CodingKeys.refererListPath.rawValue] as? String
        if let filterJSON = json[CodingKeys.urlFilter.rawValue] as? JSON {
            self.urlFilter = URLFilter(json: filterJSON)
        } else {
            Log.error { Log.message("Missing URL filter in configuration!") }
            self.urlFilter = URLFilter(exclude: [])
        }
        self.ignoreRobotsTXT = json[CodingKeys.ignoreRobotsTXT.rawValue] as? Bool ?? false
        self.ignoreSiteMap = json[CodingKeys.ignoreSiteMap.rawValue] as? Bool ?? false
        self.requestDelay = json[CodingKeys.requestDelay.rawValue] as? TimeInterval ?? 4.0
        self.requestTimeout = json[CodingKeys.requestTimeout.rawValue] as? TimeInterval ?? 60.0
        self.requestThrottling = json[CodingKeys.requestThrottling.rawValue] as? Bool ?? true
        self.urlRetriesLimit = json[CodingKeys.urlRetriesLimit.rawValue] as? Int ?? 3
        if let authJSON = json[CodingKeys.authentication.rawValue] as? JSON,
            let un = authJSON["username"] as? String,
            let pass = authJSON["password"] as? String {
                self.authentication = .usernamePassword(un, pass)
        } else {
            self.authentication = nil
        }
        self.cookies = json[CodingKeys.cookies.rawValue] as? String
    }
    
}

public extension ScrapingConfiguration {
    
    /** URL filter model. */
    public struct URLFilter {
        
        /** Regexes for URLs to exlude from crawl (login, logout, search links, etc.). */
        public var excludeURLTemplates: [String]
        
        fileprivate init(exclude: [String]) {
            self.excludeURLTemplates = exclude
        }
        
        fileprivate init(json: JSON) {
            self.init(exclude: json["exclude"] as? [String] ?? [])
        }
        
    }
    
}

public extension ScrapingConfiguration.URLFilter {
    
    /** Returns whether given URL passes through included and excluded regexes. */
    public func isURLIncluded(_ url: String) -> Bool {
        // Check excluded regexes
        for regex in excludeURLTemplates {
            if url.matchesRegex(regex) {
                // Exclude
                return false
            }
        }
        return true
    }
    
}
