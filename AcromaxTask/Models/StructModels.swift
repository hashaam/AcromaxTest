//
//  StructModels.swift
//  AcromaxTask
//
//  Created by Hashaam Siddiq on 9/2/17.
//  Copyright © 2017 Hashaam. All rights reserved.
//

import Foundation

struct ChunkStruct: CustomStringConvertible {
    let header: [String: String]
    let filename: String
    let duration: Float
    
    var description: String {
        return "Header = \(header) Filename = \(filename) Duration = \(duration)"
    }
}
