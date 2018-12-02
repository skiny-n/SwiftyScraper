//
//  Logger.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Performs all logging operations asynchronously.
 
 Uses:
 
 *To enable logging:*
 ```
 Logger.shared.logLevel = .verbose
 ```
 
 *To add a log handler:*
 ```
 Logger.shared.add(handler: ConsoleLogHandler())
 ```
 
 */
open class Logger {
    
    /** Desired log level, used for filtering messages. Defaults to `.none`. */
    open var logLevel: LogLevel = .none
    
    /** Queue used for logging so it happens outside the main thread. */
    private lazy var queue: OperationQueue = {
        let q = OperationQueue()
        q.underlyingQueue = queueDQ
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .utility
        return q
    }()
    private let queueDQ: DispatchQueue
    
    /** Log handlers to forward `Log` messages to. */
    private var handlers: [LogHandlerType] = []

    // MARK: Public
    
    /** Initializes a new instance with given queue to use for logging. */
    public init(queue: DispatchQueue = DispatchQueue(label: "cz.skiny.n.swiftyscraper.loggerQueue")) {
        self.queueDQ = queue
    }
    
    /** Registers given handler. */
    public func add(handler: LogHandlerType) {
        handlers.append(handler)
    }
    
    /** Registers given handlers. */
    public func add(handlers: [LogHandlerType]) {
        self.handlers.append(contentsOf: handlers)
    }
    
    /** Returns a log with given identifier if any exists. */
    public func handler(withIdentifier: String) -> LogHandlerType? {
        return handlers.first(where: { $0.identifier == withIdentifier })
    }
    
    /** Asynchronously logs given work on desired level. */
    public func log(_ level: LogLevel, _ stuff: @escaping () -> Log) {
        guard level <= logLevel else { return }
        if queueDQ == .main {
            if OperationQueue.current == .main {
                handlers.forEach {
                    $0.handle(log: stuff(), level: level)
                }
            } else {
                queueDQ.sync { [weak self] in
                    self?.handlers.forEach {
                        $0.handle(log: stuff(), level: level)
                    }
                }
            }
        } else {
            queue.addOperation { [weak self] in
                self?.handlers.forEach {
                    $0.handle(log: stuff(), level: level)
                }
            }
        }
    }
    
}

public extension Logger {
    
    /** Shared instance. */
    static fileprivate(set) var shared = Logger()
    
    /** Updates `shared` logger instance. */
    static func set(sharedLogger: Logger) {
        shared = sharedLogger
    }
    
}


