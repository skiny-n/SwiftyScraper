//
//  NetworkResult+Logging.swift
//  Networking-iOS
//
//  Created by Stanislav Novacek on 08/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Custom logging message.
 */
extension NetworkResult: LogInfoCustomMessageType {
    
    public var customLogMessage: String {
        switch self {
        case .success(let val, let task):
            // Success has always a response
            guard let response = task.response else { return  "Invalid response for task: \(task)" }
            var message = """
            
            
            ============================================
            <<<<<<<<<<<<<<<<  RESPONSE  <<<<<<<<<<<<<<<<
            ============================================
            STATUS:  \(response.statusCode) [\(task.metrics?.taskInterval.duration ?? -1)]
            URL:     \(response.url?.absoluteString ?? "-none-")
            HEADERS: \(response.allHeaderFields.map({ "\"\($0.key)\" = \"\($0.value)\"" }).joined(separator: "\n         "))
            """
            if let val = val as? Data, let body = String(data: val, encoding: .utf8) ?? String(data: val, encoding: .ascii) {
                message += "\nBODY:    \(body)"
            } else {
                message += "\nRESULT:  \(String(describing: val))"
            }
            message += "\n============================================"
            return message
        case .failure(let err, let task, let data):
            var message = ""
            if let r = task.response {
                message += r.customLogMessage + "\nERROR:   \(err.toError())"
                if let d = data {
                    message += "\nBODY:    \(String(data: d, encoding: .utf8) ?? String(data: d, encoding: .ascii) ?? "-none-")"
                }
            } else {
                message = "\nERROR:   \(err.toError())"
            }
            message += "\n============================================"
            return message
        }
    }
    
}
