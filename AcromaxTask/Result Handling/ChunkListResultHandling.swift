//
//  ChunkListResultHandling.swift
//  AcromaxTask
//
//  Created by Hashaam Siddiq on 9/2/17.
//  Copyright © 2017 Hashaam. All rights reserved.
//

import Foundation

final class ChunkListResultHandling: NetworkOperationResultHandling {
    
    func parse(result: Any?, completionHandler: @escaping (Any?) -> Void) {
        
        var chunks = [ChunkStruct]()
        
        var rangeStrings = [String]()
        var filenames = [String]()
        var durations = [Float]()
        
        if let value = result as? String {
            
            let lines = value.components(separatedBy: CharacterSet.newlines)
            
            let byteRangeString = "#EXT-X-BYTERANGE:"
            let infoString = "#EXTINF:"
            
            lines.forEach { line in
                
                if line.contains(byteRangeString) {
                    
                    let adjustedLine = line.replacingOccurrences(of: byteRangeString, with: "")
                    let ranges = adjustedLine.components(separatedBy: "@")
                    
                    if let first = ranges.first, let last = ranges.last, let offset = Int(last), let range = Int(first) {
                        
                        let end = offset + range
                        rangeStrings.append("\(offset)-\(end)")
                        
                    }
                    
                }
                
                if line.contains(".ts") {
                    filenames.append(line)
                }
                
                if line.contains(infoString) {
                    
                    var adjustedLine = line.replacingOccurrences(of: infoString, with: "")
                    adjustedLine = adjustedLine.replacingOccurrences(of: ",", with: "")
                    
                    if let duration = Float(adjustedLine) {
                        durations.append(duration)
                    }
                    
                }
                
            }
            
        }
        
        if !rangeStrings.isEmpty, !filenames.isEmpty, !durations.isEmpty, rangeStrings.count == filenames.count, rangeStrings.count == durations.count {
            
            for i in 0..<rangeStrings.count {
                
                let rangeString = rangeStrings[i]
                let filename = filenames[i]
                let duration = durations[i]
                
                chunks.append(
                    ChunkStruct(header: ["range": "bytes=\(rangeString)"], filename: String(format: ENDPOINT_URL, filename), duration: duration)
                )
                
            }

        }
        
        completionHandler(chunks)
        
    }
    
}
