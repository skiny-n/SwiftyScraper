//
//  LogHandlerType.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Log handler protocol.
 */
public protocol LogHandlerType {
    
    /** Unique of the handler. */
    var identifier: String { get set }
    
    /** Formatter used for creating string messages from `Log` messages. */
    var formatter: LogFormatterType { get }
    
    /** Handles given `Log` message. This function is called outside the main thread. */
    func handle(log: Log, level: LogLevel)
    
}
