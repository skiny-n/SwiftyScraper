//
//  Log.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Represents a log message.
 
 Uses:
 
 ```
 Log.debug {
     Log.message("My message").attachInfo(obj)
 }
 ```
 
 */
public final class Log: NSObject {
    
    /** Message. */
    public let message: String
    /** Timestamp. */
    public let date: Date
    /** Name of the file the log was created in. */
    public let fileName: String
    /** Name of a function the log was created in. */
    public let functionName: String
    /** Line number the log was created at. */
    public let lineNumber: UInt
    /** Custom info associated with the log message. */
    public private(set) var customInfo: Any?
    
    /** Private init. */
    private init(message: String,
                 date: Date,
                 fileName: String,
                 functionName: String,
                 lineNumber: UInt)
    {
        self.message = message
        self.date = date
        self.fileName = fileName
        self.functionName = functionName
        self.lineNumber = lineNumber
    }
    
    // MARK: Public
    
    /** Logs given closure with `info` level. */
    public static func info(_ block: @escaping () -> Log) {
        Logger.shared.log(.info, block)
    }
    
    /** Logs given closure with `warning` level. */
    public static func warning(_ block: @escaping () -> Log) {
        Logger.shared.log(.warning, block)
    }
    
    /** Logs given closure with `error` level. */
    public static func error(_ block: @escaping () -> Log) {
        Logger.shared.log(.error, block)
    }
    
    /** Logs given closure with `debug` level. */
    public static func debug(_ block: @escaping () -> Log) {
        Logger.shared.log(.debug, block)
    }
    
    /** Logs given closure with `verbose` level. */
    public static func verbose(_ block: @escaping () -> Log) {
        Logger.shared.log(.verbose, block)
    }
    
    /** Creates a log with given message. */
    public static func message(_ msg: String,
                               fileName: String = #file,
                               functionName: String = #function,
                               lineNumber: UInt = #line) -> Log
    {
        return Log(message: msg,
                   date: Date(),
                   fileName: fileName,
                   functionName: functionName,
                   lineNumber: lineNumber)
    }
    
    /** Attaches a custom object to this message. Note: only one object can be attached. */
    public func attachInfo(_ obj: Any?) -> Log {
        customInfo = obj.flatMap({ $0 })
        return self
    }
    
}

