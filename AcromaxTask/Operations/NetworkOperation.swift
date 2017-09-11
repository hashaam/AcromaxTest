//
//  ALNetworkOperation.swift
//  aamobile
//
//  Created by Hashaam Siddiq on 8/28/17.
//  Copyright © 2017 Al Arabiya. All rights reserved.
//

import Foundation
import Alamofire

enum NetworkOperationResultType {
    case success(Any?), failure(Error?)
}

protocol NetworkOperationResultHandling {
    func parse(result: Any?, completionHandler: @escaping (Any?) -> Void)
}

extension NetworkOperationResultHandling {
    func parse(result: Any?, completionHandler: @escaping (Any?) -> Void) {
        
        if DEBUG_PRINT_REQUESTS {
            print("")
            print("**** Default Parse of NetworkOperationResultHandling is being used ****")
            print("")
        }
        
        completionHandler(nil)
        
    }
}

final class NetworkOperation: CustomOperation {
    
    let urlString: String
    let method: HTTPMethod
    var parameters: Parameters?
    var headers: HTTPHeaders?
    let resultHandling: NetworkOperationResultHandling
    let completionHandler: (NetworkOperationResultType) -> Void
    
    private var request: DataRequest!
    
    init(urlString: String, method: HTTPMethod = .get, parameters: Parameters? = nil, headers: HTTPHeaders? = nil, resultHandling: NetworkOperationResultHandling, completionHandler: @escaping (NetworkOperationResultType) -> Void) {
        
        self.urlString = urlString
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.resultHandling = resultHandling
        self.completionHandler = completionHandler
        
        super.init()
        
    }
    
    override func execute() {
        
        if isCancelled {
            isFinished = true
            return
        }
        
        let initialRequest = Alamofire.request(urlString, method: method, parameters: parameters, headers: headers)
        
        if DEBUG_PRINT_REQUESTS {
            print("")
            print("**** DEBUG PRINT REQUEST ****")
            debugPrint(initialRequest)
            print("")
        }
        
        request = initialRequest.validate().responseString { [weak self] response in
            
            guard let strongSelf = self else { return }
            
            if strongSelf.isCancelled {
                strongSelf.isFinished = true
                return
            }
            
            switch response.result {
                
            case .success(let value):
                
                if DEBUG_PRINT_REQUESTS {
                    print("Success")
                    print(value)
                }
                
                strongSelf.resultHandling.parse(result: value, completionHandler: { parseResult in
                    DispatchQueue.main.async {
                        strongSelf.completionHandler(.success(parseResult))
                        strongSelf.isFinished = true
                    }
                })
                
            case .failure(let error):
                
                if DEBUG_PRINT_REQUESTS {
                    print("Error")
                    print(error.localizedDescription)
                }
                
                strongSelf.handle(error: error)
                
            }
            
        }
        
    }
    
    func handle(error: Error?) {
        
        if isCancelled {
            isFinished = true
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.completionHandler(.failure(error))
            strongSelf.isFinished = true
        }
        
    }
    
}
