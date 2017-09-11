//
//  FileDownloadOperation.swift
//  AcromaxTask
//
//  Created by Hashaam Siddiq on 9/4/17.
//  Copyright © 2017 Hashaam. All rights reserved.
//

import Foundation
import Alamofire

final class FileDownloadOperation: CustomOperation {
    
    let urlString: String
    let filename: String
    var headers: HTTPHeaders?
    let progressHandler: (Progress) -> Void
    let completionHandler: (NetworkOperationResultType) -> Void
    
    private var request: DownloadRequest!
    
    init(urlString: String, filename: String, headers: HTTPHeaders? = nil, progressHandler: @escaping (Progress) -> Void, completionHandler: @escaping (NetworkOperationResultType) -> Void) {
        self.urlString = urlString
        self.filename = filename
        self.headers = headers
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }
    
    override func execute() {
        
        if isCancelled {
            isFinished = true
            return
        }
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(self.filename)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            
        }
        
        let initialRequest = Alamofire.download(urlString, headers: headers, to: destination)
        
        if DEBUG_PRINT_REQUESTS {
            print("")
            print("**** DEBUG PRINT REQUEST ****")
            debugPrint(initialRequest)
            print("")
        }

        request = initialRequest
            .downloadProgress(closure: { [weak self] progress in
                
                guard let strongSelf = self else { return }
                strongSelf.progressHandler(progress)
//                print("\(strongSelf.filename) = \(progress.fractionCompleted)")
                
            })
            .response { [weak self] response in
            
                guard let strongSelf = self else { return }
                
                if strongSelf.isCancelled {
                    strongSelf.isFinished = true
                    return
                }
                
                
                if let error = response.error {
                    DispatchQueue.main.async {
                        
                        if DEBUG_PRINT_REQUESTS {
                            print("")
                            print("**** failed to download file ****")
                            print(error.localizedDescription)
                            print("")
                        }
                        
                        strongSelf.completionHandler(.failure(error))
                        strongSelf.isFinished = true
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    
                    if DEBUG_PRINT_REQUESTS {
                        print("")
                        print("**** successfully downloaded file ****")
                        print(response.destinationURL ?? "")
                        print("")
                    }
                    
                    strongSelf.completionHandler(.success(response.destinationURL))
                    strongSelf.isFinished = true
                }
            
        }

    }
    
}
