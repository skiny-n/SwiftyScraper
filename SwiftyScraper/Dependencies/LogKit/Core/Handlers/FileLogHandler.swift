//
//  FileLogHandler.swift
//  Logger
//
//  Created by Stanislav Novacek on 05/04/2018.
//  Copyright © 2018 Stanislav Novacek. All rights reserved.
//

import Foundation

/**
 Log handler that logs given `Log` messages into files in user's documents directory.
 In documents directory, a new directory with name given in the initializer is created if needed.
 Maximum files is specified with given count and the handlers clears old logs automatically.
 */
open class FileLogHandler: LogHandlerType {
    
    public var identifier: String
    public let formatter: LogFormatterType
    public let logsDirectoryName: String
    public let maxFiles: Int
    
    private var fileHandle: FileHandle?
    private var fileManager: FileManager { return FileManager.default }
    private var currentFileName: String {
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0).log"
    }
    
    public init(formatter: LogFormatterType = DefaultLogFormatter(),
                identifier: String = UUID().uuidString,
                directoryName: String = "logs",
                maxFiles: Int = 5)
    {
        self.identifier = identifier
        self.formatter = formatter
        self.logsDirectoryName = directoryName
        self.maxFiles = maxFiles
        // Create logs directory if needed
        createLogsDirectoryIfNeeded()
        // Delete old logs if needed
        deleteOldLogsIfNeeded()
        // Open new/current log file
        openFile()
    }
    
    deinit {
        closeFile()
    }
    
    
    // MARK: LogHandlerType
    
    /** Logs given `Log` message to current log file. */
    public func handle(log: Log, level: LogLevel) {
        var message = formatter.createMessage(from: log, level: level)
        message += "\n"
        if let data = message.data(using: .utf8), let handle = fileHandle {
            handle.write(data)
        }
    }
    
    // MARK: Public
    
    /** Returns a file URL of current log file. */
    open func currentFileURL() -> URL {
        return logsDirectory().appendingPathComponent(currentFileName)
    }
    
    /** Returns all log files in logs directory. */
    open func allLogFiles() -> [URL] {
        let directory = logsDirectory()
        guard let files = try? fileManager.contentsOfDirectory(at: directory,
                                                               includingPropertiesForKeys: [.contentModificationDateKey],
                                                               options: .skipsHiddenFiles)
            else {
                return []
        }
        return files
    }
    
    /** Returns all log files to be deleted. Sorted by modification date - oldest last. */
    open func logsToBeDeleted() -> [URL] {
        // Get all logs
        var files = allLogFiles()
        if files.count < maxFiles {
            return []
        }
        // Sort by modification date - newest first
        files.sort(by: { u1, u2 in
            let date1 = (try? u1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
            let date2 = (try? u2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
            return date1 > date2
        })
        return files
    }
    
    // MARK: Private
    
    /** Returns logs directory - documents + logs directory name. */
    private func logsDirectory() -> URL {
        #if os(macOS)
        return URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent(logsDirectoryName)
        #else
        let documents = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask).first
        return URL(fileURLWithPath: logsDirectoryName, relativeTo: documents)
        #endif
        
    }
    
    /** Creates logs directory (with any intermediate directories) if needed. */
    private func createLogsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: logsDirectory().path) {
            try? fileManager.createDirectory(at: logsDirectory(),
                                             withIntermediateDirectories: true,
                                             attributes: nil)
        }
    }
    
    /** Deletes old logs if needed. */
    private func deleteOldLogsIfNeeded() {
        // Delete oldest files over limit
        var files = logsToBeDeleted()
        while files.count >= maxFiles {
            let last = files.removeLast()
            try? fileManager.removeItem(at: last)
        }
    }

    /** Opens a new/existing log file. Closes current handle if any exists. */
    private func openFile() {
        if fileHandle != nil {
            closeFile()
        }
        do {
            let fileURL = currentFileURL()
            if !fileManager.fileExists(atPath: fileURL.path) {
                fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            }
            fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle?.seekToEndOfFile()
            if let fileHandle = fileHandle,
                let data = "\n==== START of session ====\n".data(using: .utf8)
            {
                fileHandle.write(data)
            }
        } catch _ {
            fileHandle = nil
        }
    }
    
    /** Closes current log file. */
    private func closeFile() {
        if let fileHandle = fileHandle,
            let data = "\n==== END of session ====\n".data(using: .utf8)
        {
            fileHandle.write(data)
            fileHandle.closeFile()
        }
        fileHandle = nil
    }
}

