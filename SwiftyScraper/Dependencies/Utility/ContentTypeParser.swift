//
//  ContentTypeParser.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 15/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/** Helper class for parsing content types. */
public class ContentTypeParser {
    
    /** Parsing result. */
    public struct Result {
        
        /** Type. */
        let type: String
        /** Subtype. */
        let subtype: String
        /** Additionals parameters. */
        let parameters: [String: String]
        
    }
    
    /** Tries to parse given Content-Type header value. */
    public class func parse(_ contentType: String) -> ContentTypeParser.Result? {
        var parts = contentType.split(separator: ";").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        let typeSubtype = parts.removeFirst().split(separator: "/")
        guard let type = typeSubtype.first?.lowercased(), let subtype = typeSubtype.last?.lowercased() else { return nil }
        var parameters: [String: String] = [:]
        for pair in parts {
            let split = pair.split(separator: "=")
            if let key = split.first?.lowercased(), let value = split.last {
                parameters[key] = String(value)
            }
        }
        return Result(type: type, subtype: subtype, parameters: parameters)
    }
    
}


extension ContentTypeParser.Result {
    
    /**
     Compares the receiver to another content type and returns whether they match.
     Perofms matching of `type` and `subtype`.
     Also handles values like `* / *`, `application/ *`, etc.
     */
    public func matches(contentType: String) -> Bool {
        // Parse
        guard let parsed = ContentTypeParser.parse(contentType) else { return false }
        // Type check
        if (type == "*" || parsed.type == "*") || type == parsed.type {
            // Subtype check
            return (subtype == "*" || parsed.subtype == "*") || subtype == parsed.subtype
        }
        return false
    }
    
}
