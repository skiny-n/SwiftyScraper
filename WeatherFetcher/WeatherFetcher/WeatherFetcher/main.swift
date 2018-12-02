//
//  main.swift
//  WeatherFetcher
//
//  Created by Stanislav Novacek on 23/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import SwiftyScraper

/** Global container */
enum Global {
    static var shouldTerminate = false
    fileprivate static let loop = RunLoop.current
    static var scraper: WeatherFetcher?
}

DispatchQueue.global(qos: .userInitiated).async {
    
    #if DEBUG
        // Setup logging
        Logger.set(sharedLogger: Logger(queue: .main))
        Logger.shared.logLevel = .verbose
        Logger.shared.add(handler: ConsoleLogHandler())
        Logger.shared.add(handler: FileLogHandler(maxFiles: 1))
    #endif
    
    // Get city name argument
    guard CommandLine.arguments.count == 2 else {
        Log.error { Log.message("Invalid arguments. Usage: './\(CommandLine.arguments.first!.split(separator: "/").last!) \"city\"'") }
        print("Invalid arguments. Usage: './\(CommandLine.arguments.first!.split(separator: "/").last!) \"city\"'")
        exit(ExitCodes.invalidArguments.rawValue)
    }

    // City
    let city = CommandLine.arguments[1]

    // Fontier - in-memory storage
    let urlStore: AnyPersistenceStorage = AnyPersistenceStorage(MemoryPersistenceStorage<URLEntry>())
    let historyURLStore: AnyPersistenceStorage = AnyPersistenceStorage(MemoryPersistenceStorage<URLHistoryEntry>())

    // Frontier
    let frontier = FrontierCoordinator(entryStorage: urlStore,
                                       historyEntryStorage: historyURLStore)

    // Configuration
    let configuration = FileProvier.readConfiguration()

    // Pipeline router
    let pipelineRouter = PipelineRouter.shared

    // City code pipeline
    pipelineRouter.register(pipeline: Pipeline(scraper: AnyScraper(CityCodeScraper()), persistor: nil))

    // Forecast pipeline
    pipelineRouter.register(pipeline: Pipeline(scraper: AnyScraper(HourlyForecastScraper()), persistor: nil))

    // Initialize scraper and start
    Global.scraper = WeatherFetcher(city: city, configuration: configuration, urlFrontier: frontier, pipelineRouter: pipelineRouter)
    print("Starting...")
    Global.scraper?.start()
    
}

// Keep the loop running
while Global.shouldTerminate == false && Global.loop.run(mode: .default, before: .distantFuture) { }

