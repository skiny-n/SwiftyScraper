//
//  URLEntryRedisStore.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 16/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import Kitura_Redis


/** Redis store that manages persistence and fetching of `URLEntry` entities. */
public final class URLEntryRedisStore: RedisClient {

    fileprivate enum Keys {
        static let queue = "queue"
    }
    
}


extension URLEntryRedisStore: PersistorType {
    
    public typealias PersistedEntity = URLEntry
    
    public func persist(entity: URLEntry, callback: ((Result<URLEntry>) -> Void)?) {
        inDatabase({ (redis, callback) in
            redis.rpush(Keys.queue, values: entity.redisJSONValue, callback: { (_, error) in
                if let error = error {
                    callback(.error(error, entity))
                } else {
                    callback(.success(entity))
                }
            })
        }, callback: callback)
    }
    
    public func persist(entities: [URLEntry], callback: ((Result<[URLEntry]>) -> Void)?) {
        if entities.isEmpty {
            callback?(.success(entities))
            return
        }
        inDatabase({ (redis, callback) in
            redis.rpushArrayOfValues(Keys.queue, values: entities.map({ $0.redisJSONValue }), callback: { (_, error) in
                if let error = error {
                    callback(.error(error, entities))
                } else {
                    callback(.success(entities))
                }
            })
        }, callback: callback)
    }
    
    public func removeAll(where predicate: @escaping (URLEntry) -> Bool, callback: ((Result<Void>) -> Void)?) {
        inDatabase({ (redis, completion) in
            redis.lrange(Keys.queue, start: 0, end: -1, callback: { (array, error) in
                if let error = error {
                    completion(.error(error, ()))
                } else {
                    let redisJSONValues = array?.compactMap({ $0?.asString }) ?? []
                    let entries = redisJSONValues.compactMap({ URLEntry(redisJSONValue: $0) })
                    let entriesToKeep = entries.filter({ predicate($0) == false })
                    // Delete all
                    redis.issueCommand("DEL \(Keys.queue)\r\nLPUSH \(Keys.queue) unknown", callback: { [weak self] (response) in
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
            redis.del(Keys.queue, callback: { (_, error) in
                if let error = error {
                    callback(.error(error, ()))
                } else {
                    callback(.success(()))
                }
            })
        }, callback: callback)
    }
    
}

extension URLEntryRedisStore: FetcherType {
    
    public typealias FetchedEntity = URLEntry
    
    public func fetchAll(callback: @escaping (Result<[URLEntry]>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.lrange(Keys.queue, start: 0, end: -1, callback: { (array, error) in
                if let error = error {
                    callback(.error(error, []))
                } else {
                    let redisJSONValues = array?.compactMap({ $0?.asString }) ?? []
                    let entries = redisJSONValues.compactMap({ URLEntry(redisJSONValue: $0) })
                    callback(.success(entries))
                }
            })
        }, callback: callback)
    }
    
    public func fetchFirst(callback: @escaping (Result<URLEntry?>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.lrange(Keys.queue, start: 0, end: 1, callback: { (array, error) in
                if let error = error {
                    callback(.error(error, nil))
                } else {
                    let redisJSONValues = array?.compactMap({ $0?.asString }) ?? []
                    let entries = redisJSONValues.compactMap({ URLEntry(redisJSONValue: $0) })
                    callback(.success(entries.first))
                }
            })
        }, callback: callback)
    }
    
    public func fetchFirst(where predicate: @escaping (URLEntry) -> Bool, callback: @escaping (Result<URLEntry?>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.lrange(Keys.queue, start: 0, end: -1, callback: { (array, error) in
                if let error = error {
                    callback(.error(error, nil))
                } else {
                    let redisJSONValues = array?.compactMap({ $0?.asString }) ?? []
                    let entries = redisJSONValues.compactMap({ URLEntry(redisJSONValue: $0) })
                    callback(.success(entries.first(where: predicate)))
                }
            })
        }, callback: callback)
    }
    
    public func fetchLast(callback: @escaping (Result<URLEntry?>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.lrange(Keys.queue, start: -1, end: -1, callback: { (array, error) in
                if let error = error {
                    callback(.error(error, nil))
                } else {
                    let redisJSONValues = array?.compactMap({ $0?.asString }) ?? []
                    let entries = redisJSONValues.compactMap({ URLEntry(redisJSONValue: $0) })
                    callback(.success(entries.last))
                }
            })
        }, callback: callback)
    }
    
    public func fetchAll(where predicate: @escaping (URLEntry) -> Bool, callback: @escaping (Result<[URLEntry]>) -> Void) {
        inDatabase({ (redis, callback) in
            redis.lrange(Keys.queue, start: 0, end: -1, callback: { (array, error) in
                if let error = error {
                    callback(.error(error, []))
                } else {
                    let redisJSONValues = array?.compactMap({ $0?.asString }) ?? []
                    let entries = redisJSONValues.compactMap({ URLEntry(redisJSONValue: $0) })
                    callback(.success(entries.filter(predicate)))
                }
            })
        }, callback: callback)
    }
    
}


// Helpers

fileprivate let redisJsonValuePrefix = "json:"
extension URLEntry {
    
    private var jsonString: String {
        if let data = try? JSONSerialization.data(withJSONObject: json, options: []), let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }
    var redisJSONValue: String { return redisJsonValuePrefix + jsonString }
    
    var json: JSON { return ["urlString": urlString] }
    
    init?(json: JSON) {
        if let urlString = json["urlString"] as? String {
            self.init(urlString: urlString)
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
