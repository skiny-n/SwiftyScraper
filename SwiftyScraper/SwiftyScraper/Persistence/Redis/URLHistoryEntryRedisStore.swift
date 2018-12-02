//
//  URLHistoryEntryRedisStore.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 16/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//


import Foundation
import Kitura_Redis



/** Redis store that manages persistence and fetching of `URLHistoryEntry` entities. */
public final class URLHistoryEntryRedisStore: RedisClient {
    
    fileprivate enum Keys {
        static let historyMap = "history"
    }
    
}

extension URLHistoryEntryRedisStore: PersistorType {
    
    public typealias PersistedEntity = URLHistoryEntry
    
    public func persist(entity: URLHistoryEntry, callback: ((Result<URLHistoryEntry>) -> Void)?) {
        inDatabase({ (redis, callback) in
            redis.hset(Keys.historyMap, field: entity.identifier, value: entity.redisJSONValue, callback: { (_, error) in
                if let error = error {
                    callback(.error(error, entity))
                } else {
                    callback(.success(entity))
                }
            })
        }, callback: callback)
    }
    
    public func persist(entities: [URLHistoryEntry], callback: ((Result<[URLHistoryEntry]>) -> Void)?) {
        if entities.isEmpty {
            callback?(.success(entities))
            return
        }
        inDatabase({ (redis, callback) in
            redis.hmsetArrayOfKeyValues(Keys.historyMap, fieldValuePairs: entities.map({ ($0.identifier, $0.redisJSONValue) }), callback: { (_, error) in
                if let error = error {
                    callback(.error(error, entities))
                } else {
                    callback(.success(entities))
                }
            })
        }, callback: callback)
    }
    
    public func removeAll(where predicate: @escaping (URLHistoryEntry) -> Bool, callback: ((Result<Void>) -> Void)?) {
        inDatabase({ (redis, completion) in
            redis.hgetall(Keys.historyMap, callback: { (hash, error) in
                if let error = error {
                    completion(.error(error, ()))
                } else {
                    let redisJSONValues = hash.values.compactMap({ $0.asString })
                    let entries = redisJSONValues.compactMap({ URLHistoryEntry(redisJSONValue: $0) })
                    let entriesToKeep = entries.filter({ predicate($0) == false })
                    // Delete all
                    redis.issueCommand("DEL \(Keys.historyMap)\r\nHSET \(Keys.historyMap) unknown unknown", callback: { [weak self] (response) in
                        if let error = response.asError {
                            completion(.error(error, ()))
                        } else {
                            // Pus the rest
                            self?.persist(entities: entriesToKeep, callback: { (result) in
                                switch result {
                                case .success(_): callback?(.success(()))
                                case .error(let error): callback?(.error(error))
                                }
                            })
                        }
                    })
                }
            })
        }, callback: callback)
    }
    
    public func removeAll(callback: ((Result<Void>) -> Void)?) {
        inDatabase({ (redis, callback) in
            redis.del(Keys.historyMap, callback: { (_, error) in
                if let error = error {
                    callback(.error(error, ()))
                } else {
                    callback(.success(()))
                }
            })
        }, callback: callback)
    }
    
}

extension URLHistoryEntryRedisStore: FetcherType {
    
    public typealias FetchedEntity = URLHistoryEntry
    
    public func fetchAll(callback: @escaping (Result<[URLHistoryEntry]>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.hgetall(Keys.historyMap, callback: { (hash, error) in
                if let error = error {
                    callback(.error(error, []))
                } else {
                    let redisJSONValues = hash.values.compactMap({ $0.asString })
                    let entries = redisJSONValues.compactMap({ URLHistoryEntry(redisJSONValue: $0) })
                    callback(.success(entries))
                }
            })
        }, callback: callback)
    }
    
    public func fetchFirst(callback: @escaping (Result<URLHistoryEntry?>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.hgetall(Keys.historyMap, callback: { (hash, error) in
                if let error = error {
                    callback(.error(error, nil))
                } else {
                    let redisJSONValues = hash.values.compactMap({ $0.asString })
                    let entries = redisJSONValues.compactMap({ URLHistoryEntry(redisJSONValue: $0) })
                    callback(.success(entries.first))
                }
            })
        }, callback: callback)
    }
    
    public func fetchFirst(where predicate: @escaping (URLHistoryEntry) -> Bool, callback: @escaping (Result<URLHistoryEntry?>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.hgetall(Keys.historyMap, callback: { (hash, error) in
                if let error = error {
                    callback(.error(error, nil))
                } else {
                    let redisJSONValues = hash.values.compactMap({ $0.asString })
                    let entries = redisJSONValues.compactMap({ URLHistoryEntry(redisJSONValue: $0) })
                    callback(.success(entries.first(where: predicate)))
                }
            })
        }, callback: callback)
    }
    
    public func fetchLast(callback: @escaping (Result<URLHistoryEntry?>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.hgetall(Keys.historyMap, callback: { (hash, error) in
                if let error = error {
                    callback(.error(error, nil))
                } else {
                    let redisJSONValues = hash.values.compactMap({ $0.asString })
                    let entries = redisJSONValues.compactMap({ URLHistoryEntry(redisJSONValue: $0) })
                    callback(.success(entries.last))
                }
            })
        }, callback: callback)
    }
    
    public func fetchAll(where predicate: @escaping (URLHistoryEntry) -> Bool, callback: @escaping (Result<[URLHistoryEntry]>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.hgetall(Keys.historyMap, callback: { (hash, error) in
                if let error = error {
                    callback(.error(error, []))
                } else {
                    let redisJSONValues = hash.values.compactMap({ $0.asString })
                    let entries = redisJSONValues.compactMap({ URLHistoryEntry(redisJSONValue: $0) })
                    callback(.success(entries.filter(predicate)))
                }
            })
        }, callback: callback)
    }
    
}


// Helpers

fileprivate let redisJsonValuePrefix = "json:"
extension URLHistoryEntry {
    
    private var jsonString: String {
        if let data = try? JSONSerialization.data(withJSONObject: json, options: []), let string = String(data: data, encoding: .utf8) {
            return string
        } else {
            return "{}"
        }
    }
    var redisJSONValue: String { return redisJsonValuePrefix + jsonString }
    
    var json: JSON {
        return [
            "entry": urlEntry.redisJSONValue,
            "responseCode": responseCode,
            "timestamp": timestamp
        ]
    }
    
    init?(json: JSON) {
        if let rediJSONValue = json["entry"] as? String,
            let code = json["responseCode"] as? Int,
            let ts = json["timestamp"] as? TimeInterval,
            let entry = URLEntry(redisJSONValue: rediJSONValue)
        {
            self.init(urlEntry: entry, responseCode: code, timestamp: ts)
        } else {
            return nil
        }
    }
    
    init?(redisJSONValue: String) {
        if redisJSONValue.hasPrefix(redisJsonValuePrefix) {
            var jsonValue = redisJSONValue
            jsonValue.removeFirst(redisJsonValuePrefix.count)
            if let data = jsonValue.data(using: .utf8), let json = createJSON(fromData: data) {
                self.init(json: json)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
}
