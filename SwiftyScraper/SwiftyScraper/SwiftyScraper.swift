//
//  SwiftyScraper.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


/**
 Main scraper class.
 This class coordinates the whole scraping process using its internal `Engine` instance.
 */
open class SwiftyScraper {
    
    /** Reqeust builder to use when creating requests. */
    public static var requestBuilder: RequestBuilderType = RequestBuilder()
    /** Initial response processor user for all responses. */
    public static var responseInitialProcessor: ResponseInitialProcessingType = ResponseProcessor()
    /** Whether to use host filter - stay on hosts from given start URLs. */
    public var useHostFilter: Bool {
        get { return engine.useHostFilter }
        set { engine.useHostFilter = newValue }
    }
    /** Scraping configuration this instance was initialized with. */
    public let configuration: ScrapingConfiguration
    
    /// Engine.
    private let engine: Engine
    
    /** Initializes a new instance with given start URLs and dependencies. */
    public init(startURLs: [String], configuration: ScrapingConfiguration,
                urlFrontier: FrontierCoordinatorType, pipelineRouter: PipelineRouter)
    {
        self.configuration = configuration
        self.engine = Engine(startURLs: startURLs,
                             urlFrontier: urlFrontier,
                             pipelineRouter: pipelineRouter,
                             configuration: configuration)
    }
    
    /** Starts the scraping process. */
    open func start() {
        engine.start()
    }
    
}
