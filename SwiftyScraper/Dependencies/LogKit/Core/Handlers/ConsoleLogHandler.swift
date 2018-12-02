//
//  ConsoleLogHandler.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import os.log

/**
 Log handler that logs given `Log` messages into console.
 */
open class ConsoleLogHandler: LogHandlerType {
    
    public var identifier: String
    public let formatter: LogFormatterType
    
    /** Creates a new instance with given log formatter. */
    public init(formatter: LogFormatterType = ConsoleLogFormatter(dateFormatter: nil),
                identifier: String = UUID().uuidString)
    {
        self.identifier = identifier
        self.formatter = formatter
    }
    
    public func handle(log: Log, level: LogLevel) {
        let message = formatter.createMessage(from: log, level: level)
        let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "cz.skiny.n.swiftyscraper.console-logger",
                          category: "Level \(level.description)")
        os_log("%{public}@", log: osLog, type: level.osLogType, message)
    }
    
}

extension LogLevel {
    
    /** Returns a `OSLogType` type. */
    var osLogType: OSLogType {
        switch self {
        case .none:     return .default
        case .info:     return .info
        case .warning:  return .error
        case .error:    return .fault
        case .debug:    return .debug
        case .verbose:  return .debug
        }
    }
    
}
