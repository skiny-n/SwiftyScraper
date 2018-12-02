//
//  LogHandlerType.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Implementing this protocol allows returning custom message.
 */
public protocol LogInfoCustomMessageType {
    
    /** Message that will be used when describing the receiver. */
    var customLogMessage: String { get }
    
}
