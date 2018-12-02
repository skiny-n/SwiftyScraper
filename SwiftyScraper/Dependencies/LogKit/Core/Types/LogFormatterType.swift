//
//  LogFormatterType.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Protocol for formatting a `Log` messages.
 */
public protocol LogFormatterType {
    
    /** Creates a message from given `Log` and `LogLevel`. */
    func createMessage(from log: Log, level: LogLevel) -> String
    
}
