//
//  DefaultLogFormatter.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Represents a default log formatter.
 */
open class DefaultLogFormatter: LogFormatterType {
    
    /** Date formatter used for logging. */
    public let dateFormatter: DateFormatter?
    
    /** Default initializer, uses `en_US_POSIX` locale date formatting. */
    public init() {
        dateFormatter = DateFormatter()
        dateFormatter!.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    }
    
    /** Creates a new instance with given `DateFormatter`. */
    public init(dateFormatter: DateFormatter? = nil) {
        self.dateFormatter = dateFormatter
    }
    
    // MARK: LogFormatterType
    
    /**
     Creates a message with given debug level from `Log`.
     If no date formatter is present, leaves out the `date`.
     Outputs someting like this: "[Level 📋] [MyFile.swift:37] My message".
     */
    open func createMessage(from log: Log, level: LogLevel) -> String {
        var message = ""
        // File name
        let fileName = log.fileName.components(separatedBy: "/").last ?? ""
        // Date
        if let date = dateFormatter?.string(from: log.date) {
            message += "\(date) "
        }
        // Level, file, line
        message += "\(level.description) [\(fileName):\(log.lineNumber)"
        // Function
        if level >= .verbose {
            message += " \(log.functionName)"
        }
        // Message
        message += "] \(log.message)"
        // Custom objects
        if let info = log.customInfo {
            message += descriptionFromCustomInfo(info)
        }
        return message
    }
    
    /** Description for custom info object. Has special formatting for `Log*Type`s. */
    open func descriptionFromCustomInfo(_ info: Any) -> String {
        if let info = info as? LogInfoCustomMessageType {
            return info.customLogMessage
        }
        return " \n[Custom info: \(info)]"
    }
    
}
