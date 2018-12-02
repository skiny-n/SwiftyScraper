//
//  URLRequestExtensions.swift
//  Networking-iOS
//
//  Created by Stanislav Novacek on 26/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 URLRequest estensions.
 */
public extension URLRequest {
    
    /** Returns value for given HTTP header field. */
    func value(for httpHeaderField: HTTPHederFields) -> String? {
        return value(forHTTPHeaderField: httpHeaderField.rawValue)
    }
    
    /** Whether given HTTP header field value contains given string. */
    func header(_ httpHeaderField: HTTPHederFields, contains: String) -> Bool {
        return value(for: httpHeaderField)?.contains(contains) ?? false
    }
    
    /** Sets given value for given HTTP header field. */
    mutating func set(_ value: String?, for httpHeaderField: HTTPHederFields) {
        setValue(value, forHTTPHeaderField: httpHeaderField.rawValue)
    }
    
    /**
     This method provides a way to add values to header fields incrementally.
     If a value was previously set for the given header field, the given value is
     appended to the previously-existing value. The appropriate field delimiter, a comma
     in the case of HTTP, is added by the implementation, and should not be added to the
     given value by the caller. Note that, in keeping with the HTTP RFC, HTTP header field
     names are case-insensitive.
     */
    mutating func append(_ value: String, to httpHeaderField: HTTPHederFields) {
        addValue(value, forHTTPHeaderField: httpHeaderField.rawValue)
    }
    
}

