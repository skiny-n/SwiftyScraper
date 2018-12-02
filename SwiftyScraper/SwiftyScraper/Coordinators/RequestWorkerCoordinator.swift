//
//  RequestWorkerCoordinator.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 14/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Delegate protocol for `RequestWorkerCoordinator` instances.
 */
public protocol RequestWorkerCoordinatorDelegate: AnyObject {
    
    /** Signals the delegate that a worker has finished downloading an entry. */
    func workerCoordinator(_ coordinator: RequestWorkerCoordinator,
                           workerFinished: RequestWorker,
                           withReason: ResponseProcessorResult,
                           entry: URLEntry,
                           data: Data?,
                           response: HTTPURLResponse?,
                           error: NetworkError?)
    
}

/**
 Request worker coordinator manages pool of workers for downloading URL entries.
 */
public class RequestWorkerCoordinator {
    
    /** Configuration. */
    public let configuration: ScrapingConfiguration
    /** Request builder. */
    public let requestBuilder: RequestBuilderType
    /** Response processor. */
    public let responseProcessor: ResponseInitialProcessingType
    /** Delegate. */
    public weak private(set) var delegate: RequestWorkerCoordinatorDelegate?
    /** Number of current workers. */
    public var currentWorkersCount: Int { return workers.count }
    /** Whether or not any of the workers are running. */
    public var areWorkersRunning: Bool { return workers.filter({ $0.isIdle == false }).count > 0 }
    /** Number of available workers. */
    public var availableWorkersCount: Int { return workers.filter({ $0.isIdle }).count }
    
    /// User agents to use for reqeusts.
    private(set) var userAgents: [UserAgentConfiguration] = []
    /// Referers to use for requests.
    private(set) var referers: [RefererConfiguration] = []
    /// Proxies to use for requests.
    private(set) var proxies: [ProxyConfiguration] = []
    
    /// Workers pool.
    private var workers: Set<RequestWorker> = []
    
    /** Initializes a new instance with given dependencies. */
    public init(configuration: ScrapingConfiguration,
         requestBuilder: RequestBuilderType,
         responseProcessor: ResponseInitialProcessingType,
         delegate: RequestWorkerCoordinatorDelegate)
    {
        self.configuration = configuration
        self.requestBuilder = requestBuilder
        self.responseProcessor = responseProcessor
        self.delegate = delegate
        if let agentsPath = configuration.userAgentListPath {
            self.userAgents = FileProvier.readUserAgents(at: agentsPath)
        }
        if let referersPath = configuration.refererListPath {
            self.referers = FileProvier.readReferers(at: referersPath)
        }
        if let proxiesPath = configuration.proxyListPath {
            self.proxies = FileProvier.readProxies(at: proxiesPath)
        }
        // Create workers
        for _ in 0 ..< configuration.workerLimit {
            if let worker = createWorker() {
                workers.insert(worker)
            }
        }
    }
    
    /**
     Returns (or creates if limit allows) a ready worker.
     Return `nil` if no workers are available.
     */
    public func nextWorker() -> RequestWorker? {
        // Try getting an idle worker
        if let worker = workers.first(where: { $0.isIdle }) {
            return worker
        }
        // Try creating a new worker
        return createWorker()
    }
    
    // MARK: Internal
    
    /** Creates a new cofiguration for workers. */
    func createWorkerConfiguration() -> RequestWorkerConfiguration {
        // Pick some agents
        var agents: [UserAgentConfiguration] = []
        if !userAgents.isEmpty {
            for _ in 0 ..< 5 {
                if let agent = userAgents.randomElement() {
                    agents.append(agent)
                }
            }
        }
        // Pick some referers
        var refs: [RefererConfiguration] = []
        if !referers.isEmpty {
            for _ in 0 ..< 5 {
                if let ref = referers.randomElement() {
                    refs.append(ref)
                }
            }
        }
        // Pick a proxy
        let proxy = proxies.randomElement()
        // Create a configuration
        return RequestWorkerConfiguration(maxNumberOfRequests: configuration.workerRequestLimit,
                                          userAgents: agents,
                                          proxy: proxy,
                                          referers: refs,
                                          requestDelay: configuration.requestDelay,
                                          requestTimeout: configuration.requestTimeout,
                                          requestThrottling: configuration.requestThrottling,
                                          urlRetriesLimit: configuration.urlRetriesLimit,
                                          authentication: configuration.authentication,
                                          cookies: configuration.cookies)
    }
    
    
    // MARK: Private
    
    /** Create a new worker. */
    private func createWorker() -> RequestWorker? {
        if currentWorkersCount < configuration.workerLimit {
            Log.debug { Log.message("Creating a new request worker") }
            let newWorker = RequestWorker(configuration: createWorkerConfiguration(),
                                          requestBuilder: requestBuilder,
                                          responseProcessor: responseProcessor,
                                          onFinished: { [weak self] reason, worker, entry, data, response, error in
                                            guard let ss = self else { return }
                                            if case .die = reason {
                                                // Worker's dead -> dispose
                                                Log.debug { Log.message("Request worker died") }
                                                ss.workers.remove(worker)
                                                if let newWorker = ss.createWorker() {
                                                    ss.workers.insert(newWorker)
                                                }
                                            }
                                            // No need to propagate useless callbacks
                                            if let entry = entry {
                                                ss.delegate?.workerCoordinator(ss, workerFinished: worker,
                                                                               withReason: reason,
                                                                               entry: entry,
                                                                               data: data,
                                                                               response: response,
                                                                               error: error)
                                            }
            })
            return newWorker
        }
        return nil
    }
    
}
