//
//  String+Regex.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


public extension String {
    
    func matchesRegex(_ regex: String) -> Bool {
        return matches(withRegex: regex).count > 0
    }
    
    func matches(withRegex regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            let finalResult = results.map { String(self[Range($0.range, in: self)!]) }
            return finalResult
        } catch let error {
            Log.error { Log.message("Invalid regex: \(regex) error: \(error)") }
            return []
        }
    }
    
}
