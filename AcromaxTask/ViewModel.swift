//
//  ViewModel.swift
//  AcromaxTask
//
//  Created by Hashaam Siddiq on 9/1/17.
//  Copyright © 2017 Hashaam. All rights reserved.
//

import Foundation
import Alamofire

final class ViewModel: NSObject {
    
    var request: DataRequest?
    var operationQueue = OperationQueue()
    
    var progress: Progress!
    
    var childProgress = [Progress]()
    
    let progressHandler: (Float) -> Void
    let fileReadyHandler: (Float, URL?, Error?) -> Void
    
    var totalDuration = Float(0.0)
    
    var totalChunks = 0
    var completedChunks = 0 {
        didSet {
            if completedChunks == totalChunks {
                handleDownloadCompleted()
            }
        }
    }
    
    var fileURL: URL!
    
    init(progressHandler: @escaping (Float) -> Void, fileReadyHandler: @escaping (Float, URL?, Error?) -> Void) {
        self.progressHandler = progressHandler
        self.fileReadyHandler = fileReadyHandler
        super.init()
    }
    
    func fetchPlaylist() {
        
        let resultHandling = PlaylistResultHandling()
        let networkOperation = NetworkOperation(urlString: PLAYLIST_URL, resultHandling: resultHandling) { [weak self] result in
            
            guard let strongSelf = self else { return }
            
            switch result {
                
            case .success(let uri):
                if let requiredUri = uri as? String {
                    strongSelf.fetchChunks(fileUri: requiredUri)
                }
                
            case .failure(let error):
                print(error?.localizedDescription ?? "")
                
            }
            
        }
        
        operationQueue.addOperation(networkOperation)
        
    }
    
    func fetchChunks(fileUri: String) {
        
        let endpoint = String(format: ENDPOINT_URL, fileUri)
        
        let resultHandling = ChunkListResultHandling()
        let networkOperation = NetworkOperation(urlString: endpoint, resultHandling: resultHandling) { [weak self] result in
            
            guard let strongSelf = self else { return }
            
            switch result {
                
            case .success(let data):
                if let chunks = data as? [ChunkStruct] {
                    strongSelf.processChunks(chunks: chunks)
                }
                
            case .failure(let error):
                print(error?.localizedDescription ?? "")
                
            }
            
        }
        
        operationQueue.addOperation(networkOperation)
        
    }
    
    func processChunks(chunks: [ChunkStruct]) {
        
        operationQueue.isSuspended = true
        operationQueue.maxConcurrentOperationCount = 2
        
        totalChunks = chunks.count
        completedChunks = 0
        progress = Progress(totalUnitCount: Int64(totalChunks))
        
        var totalDuration = Float(0.0)
        
        progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: [.new], context: nil)
        
        chunks
            .enumerated()
            .forEach { (order, chunk) in
                
                totalDuration += chunk.duration
            
                let filename = "file\(order).ts"
                
                let downloadOperation = FileDownloadOperation(urlString: chunk.filename, filename: filename, progressHandler: { [weak self] progress in
                    
                    guard let strongSelf = self else { return }
                    if !strongSelf.childProgress.contains(progress) {
                        strongSelf.progress.addChild(progress, withPendingUnitCount: 1)
                        strongSelf.childProgress.append(progress)
                    }
                        
                        
                    }, completionHandler: { [weak self] result in
                        
                        guard let strongSelf = self else { return }
                        
                        switch result {
                            
                        case .success(let url):
                            if let fileUrl = url as? URL {
                                strongSelf.completedChunks += 1
                            }
                            
                        case .failure(let error):
                            print(error?.localizedDescription ?? "")
                            
                        }
                        
                    })
                
                operationQueue.addOperation(downloadOperation)
            
        }
        
        self.totalDuration = totalDuration
        
        operationQueue.isSuspended = false
        
    }
    
    deinit {
        
        progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), context: nil)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard totalChunks > 0 else { return }
        
        let percentage = Float(progress.fractionCompleted)
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.progressHandler(percentage)
        }
        
    }
    
    func handleDownloadCompleted() {
        
        guard totalChunks > 0 else {
            fileReadyHandler(totalDuration, nil, nil)
            return
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        fileURL = documentsURL.appendingPathComponent("merged.ts")

        do {
        
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            let writer = try FileHandle(forWritingTo: fileURL)
            
            for i in 0..<totalChunks {
                let chunkURL = documentsURL.appendingPathComponent("file\(i).ts")
                let reader = try FileHandle(forReadingFrom: chunkURL)
                writer.write(reader.readDataToEndOfFile())
                reader.closeFile()
                
                try FileManager.default.removeItem(at: chunkURL)
            }
                
            writer.closeFile()
            
        } catch let error {
            
            print("Error occured in processing file. \(error.localizedDescription)")
            fileReadyHandler(totalDuration, nil, error)
            return
            
        }
        
        fileReadyHandler(totalDuration, fileURL, nil)
        
    }
    
    func deleteLocalFile() {
        
        do {
            
            try FileManager.default.removeItem(at: fileURL)
            
        } catch let error {
            
            print("Error occured in deleting file. \(error.localizedDescription)")
            
        }
        
    }
    
}
