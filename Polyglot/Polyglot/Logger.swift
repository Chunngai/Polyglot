//
//  Logger.swift
//  Polyglot
//
//  Created by Ho on 5/7/25.
//  Copyright © 2025 Sola. All rights reserved.
//

import Foundation

func getLogFileURL() -> URL {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    return documentsDirectory.appendingPathComponent("polyglot.log")
}

func logToFile(_ message: String) {
    let logFileURL = getLogFileURL()
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
    let logMessage = "\(timestamp): \(message)\n"
    
    if FileManager.default.fileExists(atPath: logFileURL.path) {
        // Append to existing file
        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(logMessage.data(using: .utf8)!)
            fileHandle.closeFile()
        }
    } else {
        // Create new file
        try? logMessage.write(to: logFileURL, atomically: true, encoding: .utf8)
    }
}

func readLogFile() -> String {
    let logFileURL = getLogFileURL()
    
    do {
        let logContent = try String(contentsOf: logFileURL, encoding: .utf8)
        return logContent
    } catch {
        return "No log file found or error reading: \(error)"
    }
}
