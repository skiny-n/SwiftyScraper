//
//  NetworkTaskExtensions.swift
//  Networking-iOS
//
//  Created by Stanislav Novacek on 27/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Custom logging message.
 */
extension NetworkDataTask: LogInfoCustomMessageType {

    public var customLogMessage: String {
        var bodyContent: String
        if let data = _concreteTask.originalRequest?.httpBody,
            let body = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
            bodyContent = body
        } else {
            bodyContent = "-none-"
        }
        bodyContent += "\n============================================"
        let message =
        """
        
        ============================================
        >>>>>>>>>>>>>>>>  REQUEST  >>>>>>>>>>>>>>>>>
        ============================================
        METHOD:  \(_concreteTask.originalRequest?.httpMethod ?? "-none-")
        URL:     \(_concreteTask.originalRequest?.url?.absoluteString ?? "-none-")
        HEADERS: \(_concreteTask.originalRequest?.allHTTPHeaderFields?.map({ "\"\($0.0)\" = \"\($0.1)\"" }).joined(separator: "\n         ") ?? "-none-")
        BODY:    \(bodyContent)
        """
        return message
    }
}
