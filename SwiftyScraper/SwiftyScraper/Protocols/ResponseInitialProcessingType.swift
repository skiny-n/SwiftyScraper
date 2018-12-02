//
//  ResponseInitialProcessingType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Initial response processing to decide what to do next. */
public protocol ResponseInitialProcessingType {
    
    /** Performs initial response processing and decides what to do next. */
    func process<T>(request: URLRequest, result: NetworkResult<T>) -> ResponseProcessorResult
    
}
