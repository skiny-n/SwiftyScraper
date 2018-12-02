//
//  LogLevel.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import os.log

/**
 Log levels.
 */
public enum LogLevel: Int, CustomStringConvertible, CustomDebugStringConvertible {
    
    /** Logging is disabled. */
    case none
    /** Logs messages up to `info` level. */
    case info
    /** Logs messages up to `warning` level. */
    case warning
    /** Logs messages up to `error` level. */
    case error
    /** Logs messages up to `debug` level. */
    case debug
    /** Logs messages up to `verbose` level - very verbose, including functions names. */
    case verbose
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        switch self {
        case .none:     return ""
        case .info:     return "💬"
        case .warning:  return "⚠️"
        case .error:    return "⛔"
        case .debug:    return "📋"
        case .verbose:  return "📋"
        }
    }
    
    // MARK: CustomDebugStringConvertible
    
    public var debugDescription: String { return "Log level \(rawValue): \(description)" }
}

public extension LogLevel {
    
    static func <=(lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }
    
    static func >=(lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }
    
    static func ==(lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
}
