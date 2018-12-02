//
//  FrontierCoordinatorType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Describes a frontier coordinator.
 */
public protocol FrontierCoordinatorType {
    
    /** Retrieves next entry to crawl. May return `nil` if the queue is empty or there's been an error with the queue. */
    func nextEntry(callback: @escaping (Result<URLEntry?>) -> Void)
    /** Removed given entry straight from the qeueu if found. */
    func remove(entry: URLEntry, callback: @escaping (Result<Void>) -> Void)
    /** Adds given entries to the queue. Performs duplicity and history check. */
    func save(newEntries: [URLEntry], callback: @escaping (Result<[URLEntry]>) -> Void)
    /** Saves given entry to the history. */
    func save(historyEntries: [URLHistoryEntry], callback: @escaping (Result<[URLHistoryEntry]>) -> Void)
    
}
