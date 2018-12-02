//
//  ExitCodes.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 21/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Exit codes. */
public enum ExitCodes: Int32 {
    
    /** Program finished. */
    case finished
    /** Aborted due to invalid start URLs. */
    case invalidStartURLs
    /** Aborted due to a frontier error. */
    case frontierError
    /** Aborted due to invalid agruments. */
    case invalidArguments
    
}
