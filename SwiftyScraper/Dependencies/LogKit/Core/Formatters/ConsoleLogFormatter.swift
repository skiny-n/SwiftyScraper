//
//  ConsoleLogFormatter.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Handles formatting for console-type outputs.
 */
open class ConsoleLogFormatter: DefaultLogFormatter {
    
    override open func createMessage(from log: Log, level: LogLevel) -> String {
        var message = ""
        // File name
        let fileName = log.fileName.components(separatedBy: "/").last ?? ""
        // Date
        if let date = dateFormatter?.string(from: log.date) {
            message += "\(date) "
        }
        // Level, file, line
        message += "[\(fileName):\(log.lineNumber)"
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
    
}
