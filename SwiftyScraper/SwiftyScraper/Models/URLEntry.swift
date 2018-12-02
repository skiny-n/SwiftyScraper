//
//  URLEntry.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Represents a URL entry. */
public struct URLEntry {
    
    /** URL string. */
    public let urlString: String
    /** URL. */
    public let url: URL
    /** URL components. */
    public let urlComponents: URLComponents
    
    public init?(urlString: String) {
        guard !urlString.isEmpty else { return nil }
        guard let url = URL(string: urlString) else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        self.urlString = urlString
        self.url = url
        self.urlComponents = components
        guard components.scheme != nil && components.host != nil else { return nil }
    }
    
}

extension URLEntry: IdentifiableType {
    
    public var identifier: String { return urlString }
    
}
