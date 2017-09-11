//
//  ViewController.swift
//  AcromaxTask
//
//  Created by Hashaam Siddiq on 9/1/17.
//  Copyright © 2017 Hashaam. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

enum PlayerState: String {
    case uninitialized = "Uninitialized"
    case fetching = "Fetching"
    case playing = "Playing"
    case paused = "Paused"
    case completed = "Completed"
}

class ViewController: UIViewController {
    
    @IBOutlet weak var circularProgressView: CircularProgressView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var actionImageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var stateLabel: UILabel!
    
    var viewModel: ViewModel!
    
    var playerItem: AVPlayerItem!
    var player: AVPlayer!

    var request: DataRequest?
    
    var playerState = PlayerState.uninitialized {
        didSet {
            setupPlayerStateLabel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlayerStateLabel()
        
        setupViewModel()
        
    }
    
    func setupPlayerStateLabel() {
        
        stateLabel.text = playerState.rawValue
        
    }
    
    func setupViewModel() {
        
        viewModel = ViewModel(progressHandler: { [weak self] progress in
            
            guard let strongSelf = self else { return }
            strongSelf.circularProgressView.progress = CGFloat(progress)
            strongSelf.view.layoutIfNeeded()
            
            }, fileReadyHandler: { [weak self] (totalDuration, fileURL, error) in
                
                guard let strongSelf = self else { return }
                
                if let fileURL = fileURL {
                    strongSelf.setupPlayer(fileURL: fileURL)
                    return
                }
                
                Core.showSimpleAlert(title: "Failed to download file", message: "Please try again later", viewController: strongSelf)
                
        })
        
    }

    @IBAction func actionButtonHandler(btn: UIButton) {
        
        switch playerState {
            
        case .uninitialized:
            playerState = .fetching
            viewModel.fetchPlaylist()
            actionButton.isUserInteractionEnabled = false
            
        case .fetching:
            break
        
        case .playing:
            player?.pause()
            playerState = .paused
            actionImageView.image = #imageLiteral(resourceName: "Play Icon")
            
        case .paused:
            player?.play()
            playerState = .playing
            actionImageView.image = #imageLiteral(resourceName: "Pause Icon")
            
        case .completed:
            break
            
        }
        
    }
    
    func setupPlayer(fileURL: URL) {
        
        let file = Bundle.main.url(forResource: "piano", withExtension: "m4a")!
        playerItem = AVPlayerItem(url: file)
        
        player = AVPlayer(playerItem: playerItem)
        player.play()
        
        actionImageView.image = #imageLiteral(resourceName: "Pause Icon")
        playerState = .playing
        actionButton.isUserInteractionEnabled = true
        
        circularProgressView.alpha = 0.0
        circularProgressView.strokeColor = .orange
        circularProgressView.progress = 0.0
        circularProgressView.alpha = 1.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayed), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        let time = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: time, queue: DispatchQueue.main, using: { [weak self] (time: CMTime) in
            
            guard let strongSelf = self else { return }
            
            let currentTime = CMTimeGetSeconds(strongSelf.playerItem.currentTime())
            let duration = CMTimeGetSeconds(strongSelf.playerItem.duration)
            
            if currentTime > 0.0 {
                            
                let playPercentage = currentTime / duration
                strongSelf.circularProgressView.progress = CGFloat(playPercentage)
                
            }
            
        })
        
    }
    
    func audioPlayed() {
        
        guard player != nil else { return }
        
        player.pause()
        player = nil
        playerItem = nil
        
        actionImageView.image = #imageLiteral(resourceName: "Play Icon")
        playerState = .uninitialized
        circularProgressView.strokeColor = .red
        circularProgressView.progress = 0.0
        
        viewModel.deleteLocalFile()
        
    }
    
    @IBAction func swipeHandler(swipeGestureRecognizer: UISwipeGestureRecognizer) {
        
        guard playerItem != nil else { return }
        
        let currentTime = playerItem.currentTime()
        
        switch swipeGestureRecognizer.direction {
            
        case UISwipeGestureRecognizerDirection.right:
            let newTime = CMTimeAdd(currentTime, CMTime(seconds: 5.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            playerItem.seek(to: newTime)
            
        case UISwipeGestureRecognizerDirection.left:
            let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 5.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            playerItem.seek(to: newTime)
            
        default:
            break
            
        }
        
    }

}

