//
//  RequestWorkerConfiguration.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Reqeust worker configuration. */
public struct RequestWorkerConfiguration {
    
    /** Maximum number of request before the worker dies and rotates metadata. */
    public let maxNumberOfRequests: Int
    /** User agents to rotate. */
    public let userAgents: [UserAgentConfiguration]
    /** Proxies to rotate. */
    public let proxy: ProxyConfiguration?
    /** Referers to rotate. */
    public let referers: [RefererConfiguration]
    /** Delay to use betheen requests. */
    public let requestDelay: TimeInterval
    /** Request timeout. */
    public let requestTimeout: TimeInterval
    /** Whether to use request throttling. */
    public let requestThrottling: Bool
    /** URL retries limit. */
    public let urlRetriesLimit: Int
    /** Authetication information to use for requests. */
    public let authentication: Authentication?
    /** Special cookies to use in headers. */
    public let cookies: String?
    
}
