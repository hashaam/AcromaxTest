//
//  Core.swift
//  AcromaxTask
//
//  Created by Hashaam Siddiq on 9/2/17.
//  Copyright © 2017 Hashaam. All rights reserved.
//

import UIKit

class Core {
    
    static func getGroup(line: String, key: String) -> String? {
        
        return line
            .components(separatedBy: ",")
            .filter { group in
                return group.contains(key)
            }
            .first?
            .components(separatedBy: "=")
            .last?
            .replacingOccurrences(of: "\"", with: "")
        
    }
    
}

extension Core {
    
    static func showSimpleAlert(title: String, message: String, viewController: UIViewController) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil)
        )
        viewController.present(alertController, animated: true, completion: nil)
        
    }
    
}
