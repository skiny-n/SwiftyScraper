//
//  FileProvider.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 13/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation


open class FileProvier {
    
    /** Configuration file name. */
    open class var configFileName: String { return "configuration.json" }
    
    open class var scraperLocation: String { return fileManager.currentDirectoryPath }
    open class var resourcesLocation: String { return scraperLocation + "/Resources" }
    open class var configurationLocation: String { return resourcesLocation + "/\(configFileName)" }
    
    public static let fileManager = FileManager.default
    
    /** Tries to load a text file at given path and return its lines (trimming white space and new lines characters). */
    public class func readLines(at path: String) -> [String] {
        if let data = fileManager.contents(atPath: path), let contents = String(data: data, encoding: .utf8) {
            return contents.split(separator: "\n").map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
        } else {
            Log.error { Log.message("No valid UTF-8 text file at \(path)") }
            return []
        }
    }
    
    /** Tries to read and parse a JSON file at given path. */
    public class func readJSON(at path: String) -> JSON? {
        guard let data = fileManager.contents(atPath: path) else {
            Log.error { Log.message("Could not find JSON at \(path)") }
            return nil
        }
        guard let contents = String(data: data, encoding: .utf8) else {
            Log.error { Log.message("Could not get UTF-8 content at \(path)") }
            return nil
        }
        guard let json = CommentedJSONParser.json(from: contents) else {
            Log.error { Log.message("Could not parse JSON at \(path) from contents: \(contents)") }
            return nil
        }
        return json
    }
    
}

extension FileProvier {
    
    /**
     Tries to load craper configuration from default location.
     Returns a default donfiguration in case of an error.
     */
    open class func readConfiguration() -> ScrapingConfiguration {
        if let json = readJSON(at: configurationLocation) {
            let config = ScrapingConfiguration(json: json)
            Log.info { Log.message("Loaded configuration at \(configurationLocation): \(config)") }
            return config
        } else {
            Log.error { Log.message("Could not load configuration -> using default configuration!") }
            return .defaultConfiguration
        }
    }
    
    /** Tries to read and return proxy configurations for a JSON file at given path. */
    open class  func readProxies(at path: String) -> [ProxyConfiguration] {
        if let json = readJSON(at: path), let proxies = json["proxies"] as? [JSON] {
            return proxies.compactMap(ProxyConfiguration.init)
        } else {
            Log.error { Log.message("Could not load proxy configurations!") }
            return []
        }
    }
    
    /** Tries to read and return user agent configurations for a JSON file at given path. */
    open class  func readUserAgents(at path: String) -> [UserAgentConfiguration] {
        if let json = readJSON(at: path), let agents = json["agents"] as? [String] {
            return agents.compactMap(UserAgentConfiguration.init)
        } else {
            Log.error { Log.message("Could not load user agent configurations!") }
            return []
        }
    }
    
    /** Tries to read and return referer configurations for a JSON file at given path. */
    open class  func readReferers(at path: String) -> [RefererConfiguration] {
        if let json = readJSON(at: path), let referers = json["referers"] as? [String] {
            return referers.compactMap(RefererConfiguration.init)
        } else {
            Log.error { Log.message("Could not load referer configurations!") }
            return []
        }
    }
    
}


public func dispatchAfter(_ time: TimeInterval, on: DispatchQueue = .global(), work: @escaping () -> Void) {
    on.asyncAfter(deadline: .now() + time, execute: work)
}
