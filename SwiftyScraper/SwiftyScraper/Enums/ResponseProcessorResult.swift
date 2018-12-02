//
//  ResponseProcessorResult.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Result of initial response processing.
 */
public enum ResponseProcessorResult {
    
    /** Continue with request processing */
    case `continue`
    /** Retry request (optionally specified delay in seconds) */
    case retry(after: TimeInterval?)
    /** Cancel this request */
    case cancel
    /** Signals that we have to initialize a new worker */
    case die
    
}
