//
//  CustomOperation.swift
//  aamobile
//
//  Created by Hashaam Siddiq on 1/17/17.
//  Copyright © 2017 Al Arabiya. All rights reserved.
//

import Foundation

class CustomOperation: Operation {
    
    var error: Error?
    
    var internalFinished = false
    override var isFinished: Bool {
        get {
            return internalFinished
        }
        set(newValue) {
            willChangeValue(forKey: "isFinished")
            internalFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override func main() {
        
        if isCancelled {
            isFinished = true
            return;
        }
        
        execute()
        
    }
    
    func execute() {
        
        
    }
    
}
