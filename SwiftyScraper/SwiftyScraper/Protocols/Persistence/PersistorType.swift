//
//  PersistorType.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Persisting interface of entitites.
 */
public protocol PersistorType {
    
    /** Entity. */
    associatedtype PersistedEntity
    
    /** Persists given entity. */
    func persist(entity: PersistedEntity, callback: ((Result<PersistedEntity>) -> Void)?)
    /** Persists given entity. */
    func persist(entities: [PersistedEntity], callback: ((Result<[PersistedEntity]>) -> Void)?)
    /** Removes all the entities that satisfy the given predicate. */
    func removeAll(where predicate: @escaping (PersistedEntity) -> Bool, callback: ((Result<Void>) -> Void)?)
    /** Removes all entities. */
    func removeAll(callback: ((Result<Void>) -> Void)?)
    
}

public extension PersistorType where PersistedEntity: Equatable {
    
    /** Removes given entity. */
    func remove(entity: PersistedEntity, callback: ((Result<Void>) -> Void)?) {
        removeAll(where: { $0 == entity }, callback: callback)
    }
    
    /** Removes given entities. */
    func remove(entities: [PersistedEntity], callback: ((Result<Void>) -> Void)?) {
        removeAll(where: { entities.contains($0) }, callback: callback)
    }
    
}
