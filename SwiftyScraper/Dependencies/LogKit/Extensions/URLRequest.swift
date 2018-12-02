//
//  URLRequest.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

extension URLRequest: LogInfoCustomMessageType {
    
    public var customLogMessage: String {
        let bodyContent: String
        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            bodyContent = body
        } else {
            bodyContent = "-none-"
        }
        
        return """
        
        ----> REQUEST
        METHOD:  \(httpMethod ?? "-none-")
        URL:     \(url?.absoluteString ?? "-none-")
        HEADERS: \(allHTTPHeaderFields ?? [:])
        BODY:    \(bodyContent)
        """
    }
    
}
