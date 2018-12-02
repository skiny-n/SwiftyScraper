//
//  String+Localization.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

public extension String {
    
    /** Returns localized version with `self` as a key. */
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
}
