//
//  LinkScraper.swift
//  SwiftyScraper
//
//  Created by Stanislav Novacek on 15/11/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation
import SwiftSoup

/**
 Default URL scraper.
 */
open class LinkScraper: ScraperType {
    
    /// Accepts all content types
    open var contentType: String? = nil
    /// Accepts all source URLs
    open var urlTemplate: String? = nil
    
    public typealias Entity = [URLEntry]
    
    public init() {}
    
    open func scrape(response: HTTPURLResponse, data: Data, callback: @escaping (Result<[URLEntry]>) -> Void) {
        let url = response.url?.absoluteString ?? "-unknown-"
        if !data.isEmpty {
            // We have some content to parse and scrape
            // Check for content that can be parsed via SwiftSoup
            var content: String? = nil
            if let responseContentType = response.value(for: .contentType) {
                let supportedContenTypes = ["text/html", "text/xml", "application/xhtml+xml", "application/xml"].compactMap({ ContentTypeParser.parse($0) })
                for ct in supportedContenTypes {
                    if ct.matches(contentType: responseContentType) {
                        content = String(data: data, encoding: .utf8)
                        break
                    }
                }
            }
            if content == nil {
                Log.warning { Log.message("Link scraper: no supported content type in response from \(url) - trying to parse through string using utf-8 encoding") }
                // Improvement: Use encoding from Content-Type if present
                content = String(data: data, encoding: .utf8)
            }
            guard let htmlContent = content else {
                Log.warning { Log.message("Link scraper: could not parse content from \(url)") }
                callback(.error(.parsing(nil)))
                return
            }
            // Try parsing
            DispatchQueue.global().async { [weak self] in
                do {
                    let document = try SwiftSoup.parse(htmlContent, url)
                    self?.parse(document: document, callback: { [weak self] (URLs) in
                        let entries = self?.transform(URLs: URLs, sourceURL: response.url) ?? []
                        Log.debug { Log.message("Link scraper: parsed \(entries.count) URLs") }
                        callback(.success(entries))
                    })
                } catch {
                    Log.warning { Log.message("Link scraper: could not create html document: \(error)") }
                    callback(.error(.parsing(error)))
                }
            }
        } else {
            Log.warning { Log.message("Link scraper: no content to scrape from \(url)") }
            callback(.error(.empty))
        }
    }
    
    /** The actual link parsing. Override for customization. */
    open func parse(document: Document, callback: @escaping ([String]) -> Void) {
        var urls: [String] = []
        // Try css selectors
        if let linkElements = try? document.select("a") {
            let hrefs = linkElements.array().compactMap({ try? $0.attr("href") })
            Log.debug { Log.message("Link scraper: found hrefs: \(hrefs.count)") }
            urls.append(contentsOf: hrefs)
        }
        // Improvement: More types of exctraction
        callback(urls)
    }
    
    /** URL processing before transformation. */
    open func process(URLs: [String], sourceURL: URL?) -> [String] {
        var finalURLs: [String] = []
        for var urlString in URLs {
            // Skip fragments
            if urlString.hasPrefix("#") { continue }
            // Unresolved URLs
            if urlString.hasPrefix("/www.") {
                _ = urlString.removeFirst()
            }
            // Sub domains
            if urlString.hasPrefix("//") {
                urlString.removeFirst(2)
            }
            // Sanitize unresolved paths
            if urlString.hasPrefix("/"), let host = sourceURL?.host {
                urlString = host + urlString.replacingOccurrences(of: "//", with: "/")
            }
            // Add missing protocol
            if !urlString.hasPrefix("https://") && !urlString.hasPrefix("http://") {
                urlString = "https://" + urlString
            }
            // Remove "utm_" campaigns stuff - from back
            urlString = urlString.replacingOccurrences(of: "(?:#|&)utm_[^&#]*", with: "", options: .regularExpression,
                                                       range: Range(NSRange(location: 0, length: urlString.count), in: urlString))
            // - to front
            urlString = urlString.replacingOccurrences(of: "\\?utm_[^#]*&", with: "?", options: .regularExpression,
                                                       range: Range(NSRange(location: 0, length: urlString.count), in: urlString))
            urlString = urlString.replacingOccurrences(of: "\\?utm_[^#]*", with: "", options: .regularExpression,
                                                       range: Range(NSRange(location: 0, length: urlString.count), in: urlString))
            // Remove ending slash
            if urlString.hasSuffix("/") {
                _ = urlString.removeLast()
            }
            if let url = URL(string: urlString), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                // Set query items to `nil` if it's empty
                if components.queryItems?.count == 0 {
                    components.queryItems = nil
                }
                if let newURL = components.url?.absoluteString {
                    finalURLs.append(newURL)
                }
            }
        }
        return finalURLs.uniqued
    }
    
    
    /** Last point for override before URLs are handed over to the engine. */
    open func transform(URLs: [String], sourceURL: URL?) -> [URLEntry] {
        let URLs = process(URLs: URLs, sourceURL: sourceURL)
        let entries = URLs.compactMap({ URLEntry(urlString: $0) })
        return entries.sorted(by: { e1, e2 in e1.url.depth < e2.url.depth })
    }
    
    
}
