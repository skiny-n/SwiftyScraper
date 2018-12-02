//
//  HTTPURLResponseExtensions.swift
//  Networking-iOS
//
//  Created by Stanislav Novacek on 01/05/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 HTTPURLResponse extensions.
 */
public extension HTTPURLResponse {
    
    /** Returns value for given HTTP header field. */
    func value(for httpHeaderField: HTTPHederFields) -> String? {
        if let value = allHeaderFields[httpHeaderField.rawValue] as? String {
            return value
        } else if let value = allHeaderFields[httpHeaderField.rawValue] as? Int {
            return String(value)
        } else if let value = allHeaderFields[httpHeaderField.rawValue] as? Double {
            return String(value)
        }
        return nil
    }
    
    /** Whether given HTTP header field value contains given string. */
    func header(_ httpHeaderField: HTTPHederFields, contains: String) -> Bool {
        return value(for: httpHeaderField)?.contains(contains) ?? false
    }
    
}
