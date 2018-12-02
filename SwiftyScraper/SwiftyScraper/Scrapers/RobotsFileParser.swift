//
//  RobotsFileParser.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 21/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Helper class that parses robot.txt files.
 */
public final class RobotsFileParser {
    
    /** Commandsenum */
    private enum Commands: String {
        case userAgent = "user-agent"
        case crawlDelay = "crawl-delay"
        case allow = "allow"
        case disallow = "disallow"
        case sitemap = "sitemap"
    }
    
    
    /** Parses given contents of a robots.txt file. */
    class func parse(contents: String, callback: @escaping (RobotsFilter, [SiteMap]) -> Void) {
        // Split contents to lines
        let contents = contents.split(separator: "\n").map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
        
        // Final entries
        var entries: [RobotsFilterEntry] = []
        var sitemaps: [SiteMap] = []
        // Temporary
        var crawlDelay: TimeInterval = 0
        var allows: [String] = []
        var disallows: [String] = []
        var agent: String = ""
        
        // Helper
        func createEntry() -> RobotsFilterEntry? {
            if agent.isEmpty { return nil }
            return RobotsFilterEntry(userAgent: agent, crawlDelay: crawlDelay, allow: allows, disallow: disallows)
        }
        // Helper
        func reset() {
            crawlDelay = 0
            allows = []
            disallows = []
            agent = ""
        }
        // Helper
        func createEntryAndReset() {
            if let entry = createEntry() {
                entries.append(entry)
            }
            reset()
        }
        // Helper - creates a regex from given template
        func sanitized(template: String) -> String {
            var template = template
            // Ignore last *
            if template.hasSuffix("*") {
                _ = template.removeLast()
            }
            // Only / -> .*
            if template == "/" || template.isEmpty {
                return ".*"
            }
            // Remove starting /
            if template.hasPrefix("/") {
                _ = template.removeFirst()
            }
            // / -> \/
            template = template.replacingOccurrences(of: "/", with: "\\/")
            // . -> \.
            template = template.replacingOccurrences(of: ".", with: "\\.")
            // * -> .*?
            template = template.replacingOccurrences(of: "*", with: ".*?")
            // /$ ending
            if template.hasSuffix("/$") {
                template.removeLast(2)
                template.append("\\/.*?\\/")
            }
                // $ ending
            else if template.hasSuffix("$") {
                // nothing
            }
                // / ending
            else if template.hasSuffix("/") {
                // nothing
            }
                // Begins with a number or a letter -> ^...
            else if let first = template.lowercased().first, ("a"..."z").contains(first) || ("0"..."9").contains(first) {
                template = "^" + template
            }
            // Done
            return template
        }
        
        // Process each line
        for var line in contents {
            // Trim white spaces
            line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip comments
            if line.hasPrefix("#") { continue }
            // Separate to command and template
            let split = line.split(separator: ":")
            guard let commandString = split.first?.trimmingCharacters(in: .whitespacesAndNewlines),
                let template = split.last?.trimmingCharacters(in: .whitespacesAndNewlines),
                commandString.isEmpty == false && template.isEmpty == false
                else { continue }
            // Skip unknown commands
            guard let command = Commands(rawValue: commandString.lowercased()) else { continue }
            switch command {
            case .userAgent:
                // Another agent -> save existing and create a new one
                createEntryAndReset()
                agent = sanitized(template: template)
            case .crawlDelay:
                // Set dela
                crawlDelay = TimeInterval(template) ?? 0
            case .allow:
                // Add to allows
                allows.append(sanitized(template: template))
            case .disallow:
                // Add to disallows
                disallows.append(sanitized(template: template))
            case .sitemap where template.hasSuffix(".xml"):
                // Save existing agent (if any) and create a sitemap
                createEntryAndReset()
                if let url = URL(string: template.hasPrefix("https:") ? template : ("https:" + template)) {
                    sitemaps.append(SiteMap(url: url, lastUpdated: nil, entries: []))
                }
            default: continue
            }
        }
        
        let filter = RobotsFilter(entries: entries)
        callback(filter, sitemaps)
    }
    
}
