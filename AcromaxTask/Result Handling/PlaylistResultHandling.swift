//
//  PlaylistResultHandling.swift
//  AcromaxTask
//
//  Created by Hashaam Siddiq on 9/2/17.
//  Copyright © 2017 Hashaam. All rights reserved.
//

import Foundation

final class PlaylistResultHandling: NetworkOperationResultHandling {
    
    func parse(result: Any?, completionHandler: @escaping (Any?) -> Void) {
        
        var requiredUri: String?
        
        if let value = result as? String {
                        
            let lines = value.components(separatedBy: CharacterSet.newlines)
            let audioLines = lines.filter { line in
                return line.contains("TYPE=AUDIO")
            }
            
            var audioLineDict: [String: String] = [:]
            
            audioLines.forEach { line in
                
                if let groupValue = Core.getGroup(line: line, key: "GROUP-ID") {
                    audioLineDict[groupValue] = line
                }
                
            }
            
            if let lastKey = audioLineDict.keys.sorted().last, let lastLine = audioLineDict[lastKey] {
                
                if let uri = Core.getGroup(line: lastLine, key: "URI") {
                    requiredUri = uri
                }
                
            }
            
        }
        
        completionHandler(requiredUri)
        
    }
    
}
