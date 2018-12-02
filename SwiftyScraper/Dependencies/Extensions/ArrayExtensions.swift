//
//  ArrayExtensions.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


public extension Array where Element: Hashable {
    
    var uniqued: Array {
        return Array(Set(self))
    }
    
}
