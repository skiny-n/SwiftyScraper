//
//  Result.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Result type.
 */
public enum Result<Value> {
    
    /** Success case with a value. */
    case success(Value)
    /** Error case with an error. */
    case error(SwiftyScraperError)
    
}
