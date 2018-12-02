//
//  HTTPMethod.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 HTTP methods.
 */
public enum HTTPMethod: String {
    
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case head    = "HEAD"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace   = "TRACE"
    
}
