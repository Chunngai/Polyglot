//
//  IO.swift
//  Polyglot
//
//  Created by Sola on 2023/1/1.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

func constructFileUrl(from fileName: String, create: Bool) throws -> URL {
    do {
        let fileURL = try FileManager
            .default
            .url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: create
        )
            .appendingPathComponent(fileName)
        
        return fileURL
    } catch let error as URLError {
        throw error
    }
}

func readDataFromJson<T: Decodable>(fileName: String, type: T.Type) throws -> Any? {
    
    // https://stackoverflow.com/questions/57665746/swift-5-xcode-11-betas-5-6-how-to-write-to-a-json-file
    // https://stackoverflow.com/questions/24308975/how-to-pass-a-class-type-as-a-function-parameter
    // https://stackoverflow.com/questions/52539444/printing-decodingerror-details-on-decode-failed-in-swift
    
    do {
        let fileURL = try constructFileUrl(from: fileName, create: false)
        let data = try Data(contentsOf: fileURL)
        let items = try JSONDecoder().decode(T.self, from: data)
        
        return items
    } catch let error as CocoaError {
        if error.code.rawValue == 260 {
            print(error)  // File not exists.
            return []
        }
        throw error
    } catch let error as DecodingError {
        throw error
    }
}

func writeDataToJson<T: Encodable>(fileName: String, data: T) throws {
    
    do {
        let fileURL = try constructFileUrl(from: fileName, create: true)
        try JSONEncoder()
            .encode(data)
            .write(to: fileURL)
    } catch let error as EncodingError {
        throw error
    }
    
}
