//
//  Pipeline.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Pipeline consists of a scraper and a persistor (optional).
 The basic idea is that a scraper is fed response data and after parsing
 some info from this data this info is passed to a persistor that takes
 care of persisting this formatted info to a database, file, remote server, etc.
 */
open class Pipeline<Entity: IdentifiableType>: PipelineType {
    
    /** Pipeline identifier. */
    public let id: String = UUID().uuidString
    
    /** Content-Type this pipeline is able to parse. */
    open var contentType: String? { return scraper.contentType }
    /** URL template (regex) that this pipeline is able to handle. */
    open var urlTemplate: String? { return scraper.urlTemplate }
    /** Whether or not the pipeline is running (processing data). */
    public private(set) var isRunning: Bool = false
    
    /** Scraper. */
    public let scraper: AnyScraper<[Entity]>
    /** Persistor. */
    public let persistor: AnyPersistor<Entity>?
    
    /** Initializes a new instance with given scraper and persistor. */
    public init(scraper: AnyScraper<[Entity]>, persistor: AnyPersistor<Entity>?) {
        self.scraper = scraper
        self.persistor = persistor
    }
    
    /**
     Feeds given response and data to the pipeline. Callback is called when the pipeline finishes.
     */
    public func feed(response: HTTPURLResponse, data: Data, callback: ((Result<Any>) -> Void)?) {
        // Scrape -> feed to persistor
        isRunning = true
        scraper.scrape(response: response, data: data) { [weak self] (result) in
            // Scraping done
            switch result {
            case .success(let entities):
                if let persistor = self?.persistor {
                    // Persis
                    persistor.persist(entities: entities, callback: { (result) in
                        self?.isRunning = false
                        switch result {
                        case .success(_):       callback?(.success(entities))
                        case .error(let error): callback?(.error(error))
                        }
                    })
                } else {
                    callback?(.success(entities))
                }
            case .error(let error):
                Log.error { Log.message("Error while scraping \(response.url?.absoluteString ?? "-unknown-") \(error)") }
                self?.isRunning = false
                callback?(.error(error))
            }
        }
    }
    
}
