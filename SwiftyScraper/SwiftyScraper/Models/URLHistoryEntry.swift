//
//  URLHistoryEntry.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/** Represents a URL history entry. */
public struct URLHistoryEntry {
    
    /** URL entry. */
    public let urlEntry: URLEntry
    /** Response code from URL response. */
    public let responseCode: Int
    /** Creation timestamp. */
    public let timestamp: TimeInterval
    
    public init(urlEntry: URLEntry, responseCode: Int, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.urlEntry = urlEntry
        self.responseCode = responseCode
        self.timestamp = timestamp
    }
    
}

extension URLHistoryEntry: IdentifiableType {
    
    public var identifier: String { return urlEntry.identifier }
    
}
