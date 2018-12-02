//
//  FrontierCoordinator.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Frontier coordinator manages URL frontier and URL history.
 This coordinator is responsible for adding (filtering duplicates) URLs to the queue
 and for keeping track of already successfuly visited URLs.
 */
public class FrontierCoordinator {
    
    private let urlEntryStorage: AnyPersistenceStorage<URLEntry>
    private let urlHistoryStorage: AnyPersistenceStorage<URLHistoryEntry>
    
    public init(entryStorage: AnyPersistenceStorage<URLEntry>, historyEntryStorage: AnyPersistenceStorage<URLHistoryEntry>) {
        self.urlEntryStorage = entryStorage
        self.urlHistoryStorage = historyEntryStorage
    }
    
}

extension FrontierCoordinator: FrontierCoordinatorType {
    
    public func nextEntry(callback: @escaping (Result<URLEntry?>) -> Void) {
        // Try fetching first in the queue
        urlEntryStorage.fetchFirst { [weak self] (result) in
            switch result {
            case .success(let entry):
                // Success
                if let entry = entry {
                    // Remove from queue
                    self?.urlEntryStorage.remove(entity: entry, callback: { [weak self] (result) in
                        switch result {
                        case .success:
                            // Filter out - may be some left overs from error sessions
                            self?.filterOutDuplicates(from: [entry], callback: { result in
                                switch result {
                                case .success(let entries):
                                    callback(.success(entries.first))
                                case .error(let error):
                                    callback(.error(error))
                                }
                            })
                        case .error(let error):
                            callback(.error(error))
                        }
                    })
                } else {
                    // Empty queue
                    callback(.success(nil))
                }
            case .error(let error): callback(.error(error))
            }
        }
    }
    
    public func remove(entry: URLEntry, callback: @escaping (Result<Void>) -> Void) {
        urlEntryStorage.remove(entity: entry) { (result) in
            callback(result)
        }
    }
    
    public func save(newEntries: [URLEntry], callback: @escaping (Result<[URLEntry]>) -> Void) {
        filterOutDuplicates(from: newEntries) { [weak self] result in
            switch result {
            case .success(let entries):
                Log.debug { Log.message("Adding \(entries.count) entries to the queue \n\(entries.map({ $0.urlString }).joined(separator: "\n"))") }
                self?.urlEntryStorage.persist(entities: newEntries, callback: callback)
            case .error(let error):
                callback(.error(error))
            }
        }
    }
    
    public func save(historyEntries: [URLHistoryEntry], callback: @escaping (Result<[URLHistoryEntry]>) -> Void) {
        // Filter out duplicates
        let historyEntries = historyEntries.uniqued
        Log.debug { Log.message("Persisting \(historyEntries.count) history entries: \n\(historyEntries.map({ $0.urlEntry.urlString }).joined(separator: "\n"))") }
        urlHistoryStorage.persist(entities: historyEntries, callback: callback)
    }
    
    // MARK: Private
    
    private func filterOutDuplicates(from entries: [URLEntry], callback: @escaping (Result<[URLEntry]>) -> Void) {
        // Filter out duplicates
        let entries = entries.uniqued
        // Check against history
        urlHistoryStorage.fetchAll(where: { entries.contains($0.urlEntry) }) { (result) in
            switch result {
            case .success(let historyEntries):
                // History entries
                let historyEntries = historyEntries.map({ $0.urlEntry })
                // Filter out duplicates
                let unique = entries.filter({ !historyEntries.contains($0) })
                callback(.success(unique))
            case .error( let error):
                // Error -> return entries
                callback(.error(error))
            }
        }
    }
    
}
