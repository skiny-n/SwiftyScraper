//
//  RefererConfiguration.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Referer configuration. */
public struct RefererConfiguration {
    
    /** Referer header value. */
    public let header: String
    
    /** Instantiates a new instance with given header value. */
    init(header: String) {
        self.header = header
    }
    
}
