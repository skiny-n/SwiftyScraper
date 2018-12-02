//
//  HTTPURLResponse.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

extension HTTPURLResponse: LogInfoCustomMessageType {
    
    public var customLogMessage: String {
        
        return """
        
        <---- RESPONSE
        STATUS:  \(statusCode)
        URL:     \(url?.absoluteString ?? "-none-")
        HEADERS: \(allHeaderFields as? [String: Any] ?? [:])
        """
    }
    
}
