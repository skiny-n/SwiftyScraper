//
//  SwiftyScraperError.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/** Errors. */
public enum SwiftyScraperError: Error {
    
    /** Empty result. */
    case empty
    /** Parsing error. */
    case parsing(Error?)
    /** Unsupported content type. */
    case unsupportedContentType
    /** Persistence error. */
    case persistence(Error?)
    /** General unknown error outside this framework domain. */
    case unknown(Error?)
    
}


