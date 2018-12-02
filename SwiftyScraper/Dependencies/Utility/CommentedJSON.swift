//
//  CommentedJSON.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 A commented JSON parser.
 Filters out multi-line and single line comments from a source JSON string.
 
 ```
 { /* filtered comment */ /*filtered comment*/
     "images" : [ /* filtered comment */
     {
         "idiom" : "universal", /* filtered comment */
         "filename" : /* filtered comment */  "icon.png",
         "scale" : "1x"
     },
     {
         "idiom" : "universal",
         "filename" : "icon@2x.png",
         "scale" : "2x" /* filtered comment */
     },
     {
         "idiom" : "universal",
         "filename" /* filtered comment */: "// inside ", // filtered comment
         "scale"/* filtered comment */ : "3x"
     }
     ],
     /* filtered comment */
     "info" : {
         "version" : 1,
         "author" : "xcode/* inside */"
     }
 }
 // filtered comment
 //filtered comment
 /* filtered comment */
 /**/
 /* filtered comment
 
 */
 /*
 (filtered comment)
 */
 ```
 
 */
public struct CommentedJSONParser {
    
    /** Regexes */
    private enum Regexes {
        
        static let singleLineComments = "(?<singleline>\\/\\/[^\n\r]*(?:[\n\r]+|$))"
        static let multiLineComments = "(?<multiline>\\/\\*(?:(?!\\*\\/).|[\n\r])*\\*\\/)"
        static let everythingInQuotes = "(?:(([\"'])(?:(?:\\\\\\\\)|\\\\\\2|(?!\\\\\\2)\\\\|(?!\\2).|[\n\r])*\\2))"
        static let allComments = [everythingInQuotes, multiLineComments, singleLineComments].joined(separator: "|")
        
    }
    
    private static let regex = try! NSRegularExpression(pattern: Regexes.allComments, options: .caseInsensitive)
    
    /** Parses and returns a JSON from given source JSON string. This string may contain comments that will be parsed out. */
    public static func json(from string: String) -> JSON? {
        // Get all matches
        let matches = regex.matches(in: string, options: [], range: NSMakeRange(0, string.count))
        // Filter only comment matches
        let ranges: [NSRange] = matches.filter({
            $0.range(withName: "singleline").location != NSNotFound || $0.range(withName: "multiline").location != NSNotFound
        }).map({ $0.range })
        // Filtered string
        var filteredString = string
        // Remove comments
        for r in ranges.reversed() {
            filteredString.removeSubrange(Range(r, in: string)!)
        }
        // Try to parse filtered JSON string
        do {
            if let data = filteredString.data(using: .utf8), let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSON {
                return json
            } else {
                Log.error { Log.message("Could not parse JSON from given filtered string: \(filteredString).") }
                return nil
            }
        } catch {
            Log.error { Log.message("Could not parse JSON from given filtered string: \(filteredString). Error: \(error)") }
            return nil
        }
    }
    
}

/** Dictionary type only! */
public typealias JSON = [String: Any]


