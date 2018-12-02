//
//  Authentication.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/** Type of authentication. */
public enum Authentication {
    
    /** Username and password authentication. */
    case usernamePassword(String, String)
    
}
