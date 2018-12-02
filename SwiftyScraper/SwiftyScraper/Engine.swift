//
//  Engine.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 12/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Scraper engine.
 This class coordinates the whole scraping process.
 */
public class Engine {
    
    /** Scraping configuration. */
    public let configuration: ScrapingConfiguration
    /** URL frontier. */
    public let urlFrontier: FrontierCoordinatorType
    /** Pipeline router. */
    public let pipelineRouter: PipelineRouter
    /** Worker coordinator. */
    public private(set) var workerCoordinator: RequestWorkerCoordinator!
    /** Host filtering - stay on hosts from given start URLs. */
    public var useHostFilter = true
    
    /// Hosts for filtering extracted URL entries.
    private var hosts: [String]
    /// Robots.txt filter.
    private var robotsFilters: [RobotsFilter] = []
    /// Total number of processed entries.
    private var processedEntriesCount = 0 {
        didSet {
            let limit = configuration.urlCountLimit
            if limit > 0 && processedEntriesCount >= limit {
                Log.info { Log.message("Reached \(limit) processed URLs - exiting") }
                exit(ExitCodes.finished.rawValue)
            }
        }
    }
    /// Entries that started this scraping process.
    private var startEntries: [URLEntry] = []
    /// Temporary helper for robots and sitemaps
    private var tempWorker: RequestWorker?
    
    /** Initializes a new instance with given start URLs and other dependencies. */
    public init(startURLs: [String],
                urlFrontier: FrontierCoordinatorType,
                pipelineRouter: PipelineRouter,
                configuration: ScrapingConfiguration)
    {
        // Start URLs check
        let entries = startURLs.compactMap({ URLEntry(urlString: $0) })
        guard entries.count > 0 else {
            Log.error { Log.message("No (valid) start URL(s) given - exiting") }
            exit(ExitCodes.invalidStartURLs.rawValue)
        }
        
        self.hosts = entries.compactMap({ $0.urlComponents.host })
        self.urlFrontier = urlFrontier
        self.configuration = configuration
        self.pipelineRouter = pipelineRouter
        self.workerCoordinator =
            RequestWorkerCoordinator(configuration: configuration,
                                     requestBuilder: SwiftyScraper.requestBuilder,
                                     responseProcessor: SwiftyScraper.responseInitialProcessor,
                                     delegate: self)
        
        // Filter given start URLs
        let filteredEntries = filter(entries: entries)
        guard filteredEntries.count > 0 else {
            Log.error { Log.message("Start URLs didn't go through URL filtering - nothing to download - exiting") }
            exit(ExitCodes.finished.rawValue)
        }
        startEntries = filteredEntries
    }
    
    /** Starts the scraping process. */
    public func start() {
        Log.info { Log.message("Starting crawling...") }
        // Add entries to the frontier
        addToQueue(entries: startEntries) { [weak self] in
            guard let ss = self else { return }
            ss.nextEntry { [weak self] (entry) in
                guard let ss = self else { return }
                // Fetch robots.txt
                if ss.configuration.ignoreRobotsTXT {
                    // Scrape away
                    ss.process(entry: entry)
                } else {
                    // Try fetching robots.txt for each host
                    var robotEntries: [URLEntry] = []
                    for host in ss.hosts {
                        if let e = URLEntry(urlString: "https://\(host)/robots.txt") {
                            robotEntries.append(e)
                        }
                    }
                    if robotEntries.count > 0 {
                        // Fetch robots.txt for each host
                        let group = DispatchGroup()
                        for re in robotEntries {
                            group.enter()
                            Log.debug { Log.message("Fetching robots.txt for \(re.url)") }
                            ss.fetchRobotsTXT(from: re, callback: { [weak self] (filter) in
                                guard let ss = self else { return }
                                if let filter = filter {
                                    ss.robotsFilters.append(filter)
                                }
                                group.leave()
                            })
                        }
                        group.notify(queue: .global()) { [weak self] in
                            // Scrape away
                            self?.process(entry: entry)
                        }
                    } else {
                        // Scrape away
                        ss.process(entry: entry)
                    }
                }
            }
        }
    }
    
    // MARK: Private
    
    private func nextEntriesAndProcess() {
        for _ in 0 ..< workerCoordinator.availableWorkersCount {
            nextEntry { [weak self] (entry) in
                self?.process(entry: entry)
            }
        }
    }
    
    private func process(entry: URLEntry) {
        if let worker = workerCoordinator.nextWorker() {
            worker.startWorking(with: entry)
        } else {
            // No available workers -> try again later
            dispatchAfter(2) { [weak self] in
                self?.process(entry: entry)
            }
        }
    }
    
    private func fetchRobotsTXT(from entry: URLEntry, callback: @escaping (RobotsFilter?) -> Void) {
        let config = workerCoordinator.createWorkerConfiguration()
        tempWorker = RequestWorker(configuration: config, requestBuilder: workerCoordinator.requestBuilder, responseProcessor: workerCoordinator.responseProcessor) { (_, _, _, data, response, error) in
            // Interested only in data
            if let data = data, let contents = String(data: data, encoding: .utf8) {
                RobotsFileParser.parse(contents: contents, callback: { [weak self] (filter, siteMaps) in
                    // Return filter
                    callback(filter)
                    // Process sitemaps
                    guard let ss = self, let worker = ss.tempWorker else { return }
                    for sm in siteMaps {
                        if let e = URLEntry(urlString: sm.url.absoluteString) {
                            ss.workerCoordinator(ss.workerCoordinator, workerFinished: worker, withReason: .continue, entry: e, data: data, response: response, error: error)
                        }
                    }
                })
            } else {
                Log.error { Log.message("Could not fetch robots.txt from \(entry.url)") }
                callback(nil)
            }
        }
        tempWorker?.startWorking(with: entry)
    }
    
    /** Filters given entries and saves them to the queue. */
    private func addToQueue(entries: [URLEntry], callback: @escaping () -> Void) {
        let filtered = filter(entries: entries)
        self.urlFrontier.save(newEntries: filtered) { result in
            if case let .error(error) = result {
                Log.error { Log.message("Error adding entries to the queue - exiting! (Error: \(error)") }
                exit(ExitCodes.frontierError.rawValue)
            }
            callback()
        }
    }
    
    private func nextEntry(callback: @escaping (URLEntry) -> Void) {
        urlFrontier.nextEntry { [weak self] (result) in
            guard let ss = self else { return }
            switch result {
            case .success(let entry):
                if let entry = entry {
                    // Filter the entry in case something slipped from previous executions and that kind of stuff
                    if let entry = ss.filter(entries: [entry]).first {
                        callback(entry)
                    } else {
                        // Ivalid entry -> remove and fetch a new one
                        ss.urlFrontier.remove(entry: entry, callback: { [weak self] result in
                            if case let .error(error) = result {
                                Log.error { Log.message("Error removing entry from queue - exiting! (Error: \(error)") }
                                exit(ExitCodes.frontierError.rawValue)
                            } else {
                                // Try next entry
                                self?.nextEntry(callback: callback)
                            }
                        })
                    }
                } else {
                    if ss.workerCoordinator.areWorkersRunning || ss.pipelineRouter.isRunning {
                        // Still working -> try again after few seconds
                        Log.debug { Log.message("No next entry but workers or pipelines still running - will ask for next entry again") }
                        dispatchAfter(3, work: { [weak self] in
                            self?.nextEntry(callback: callback)
                        })
                    } else {
                        // Nothing is running -> finished
                        Log.info { Log.message("Finished!") }
                        exit(ExitCodes.finished.rawValue)
                    }
                }
            case .error(let error):
                Log.error { Log.message("Error fetching next URL - exiting! (Error: \(error))") }
                exit(ExitCodes.frontierError.rawValue)
            }
        }
    }
    
    private func filter(entries: [URLEntry]) -> [URLEntry] {
        let filteredEntries = entries.uniqued.filter({ (entry) -> Bool in
            var included = true
            // Host filter
            if let host = entry.urlComponents.host, useHostFilter {
                included = included && hosts.contains(host)
            }
            if !included {
                Log.warning { Log.message("URL filter - (host filter) filtering out \(entry.urlString)") }
                return false
            }
            // Filter through both robots filter and URL filter
            for filter in robotsFilters {
                for ua in workerCoordinator.userAgents {
                    let isOK = filter.isAllowed(url: entry.urlString, forAgent: ua.header)
                    if isOK == false {
                        Log.warning { Log.message("URL filter - (robots.txt filter) filtering out \(entry.urlString)") }
                        return false
                    }
                }
            }
            // Filter our configuration URL filter
            included = included && configuration.urlFilter.isURLIncluded(entry.urlString)
            if !included {
                Log.warning { Log.message("URL filter - (config url filter) filtering out \(entry.urlString)") }
                return false
            }
            // Depth level
            if configuration.depthLimit > 0 {
                included = included && entry.url.depth <= configuration.depthLimit
            }
            if !included {
                Log.warning { Log.message("URL filter - (depth filter) filtering out \(entry.urlString)") }
                return false
            }
            return included
        })
        return filteredEntries
    }
    
}

extension Engine: RequestWorkerCoordinatorDelegate {
    
    public func workerCoordinator(_ coordinator: RequestWorkerCoordinator, workerFinished: RequestWorker, withReason: ResponseProcessorResult, entry: URLEntry, data: Data?, response: HTTPURLResponse?, error: NetworkError?) {
        switch withReason {
        case .retry(after: _), .die:
            // Put the entry back to the queue
            addToQueue(entries: [entry]) { [weak self] in
                // Continue scraping
                self?.nextEntriesAndProcess()
            }
        case .continue where response != nil:
            // Fetch successfull -> save to history, route to pipelines
            let historyEntry = URLHistoryEntry(urlEntry: entry, responseCode: response!.statusCode)
            urlFrontier.save(historyEntries: [historyEntry]) { [weak self] result in
                guard let ss = self else { return }
                if case let .error(error) = result {
                    Log.error { Log.message("Error saving history entries - exiting! (Error: \(error)") }
                    exit(ExitCodes.frontierError.rawValue)
                }
                // Route to pipelines
                Log.debug { Log.message("Routing \(entry.urlString) to pipelines") }
                ss.pipelineRouter.route(response: response!, data: data ?? Data(), callback: { [weak self] result in
                    // Increment downloaded URLs count
                    self?.processedEntriesCount += 1
                    // Add links from links pipeline to queue
                    if case let .success(value) = result, let entries = value as? [URLEntry] {
                        self?.addToQueue(entries: entries)  { [weak self] in
                            // Continue scraping
                            self?.nextEntriesAndProcess()
                        }
                    } else {
                        // Continue scraping
                        self?.nextEntriesAndProcess()
                    }
                })
            }
        default:
            // Treat as downloaded so this entry will never be downloaded again
            Log.warning { Log.message("Ignoring result from \(entry.url) error: \(String(describing: error)) - but saving to history for filtering") }
            let historyEntry = URLHistoryEntry(urlEntry: entry, responseCode: response?.statusCode ?? -1)
            urlFrontier.save(historyEntries: [historyEntry]) { [weak self] result in
                if case let .error(error) = result {
                    Log.error { Log.message("Error saving history entries - exiting! (Error: \(error)") }
                    exit(ExitCodes.frontierError.rawValue)
                }
                // Continue scraping
                self?.nextEntriesAndProcess()
            }
        }
    }
    
}
