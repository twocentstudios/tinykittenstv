//
//  VideoViewController.swift
//  tinykittenstv
//
//  Created by Christopher Trott on 4/13/17.
//  Copyright © 2017 twocentstudios. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result
import XCDYouTubeKit
import AVFoundation
import Mortar

final class VideoViewController: UIViewController {
    
    enum ViewState {
        case inactive
        case mayBecomeActive
        case active
    }
    
    let client: XCDYouTubeClient
    let videoInfo: LiveVideoInfo
    
    lazy var playerView: PlayerView = PlayerView()
    lazy var descriptionView: VideoDescriptionView = VideoDescriptionView()
    lazy var loadingView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    let userPlayState = MutableProperty(UserPlayState.play)
    let viewState = MutableProperty(ViewState.inactive)
    private let loading: Property<Bool>
    private let player: Property<AVPlayer?>
    
    private let fetchAction: Action<(), XCDYouTubeVideo, NSError>
    
    init(videoInfo: LiveVideoInfo, client: XCDYouTubeClient) {
        self.videoInfo = videoInfo
        self.client = client
        
        fetchAction = Action { _ -> SignalProducer<XCDYouTubeVideo, NSError> in
            return client.rac_getVideoWithIdentifier(videoInfo.id)
                .start(on: QueueScheduler())
        }
        
        // TODO: error?
        // let errors = fetchAction.errors.map { $0 }
        let values = fetchAction.values
            .map { (video: XCDYouTubeVideo) -> URL? in
                return video.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming]
            }
            .skipRepeats({ $0 == $1 })
            .map { (url: URL?) -> AVPlayer? in
                guard let url = url else { return nil }
                let player = AVPlayer(url: url)
                return player
            }
        
        self.player = ReactiveSwift.Property(initial: nil, then: values)
        
        let infoLoading = fetchAction.isExecuting.producer.prefix(value: false)
        let playerUnavailable = player.producer.map({ $0 == nil }).prefix(value: false)
        let playerLoading = player.producer
            .map { $0?.currentItem }
            .skipNil()
            .flatMap(.latest) { (playerItem: AVPlayerItem) -> Signal<Bool, NoError> in
                return playerItem.reactive.signal(forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty)).skipNil().map({ $0 as! Bool })
            }
            .prefix(value: false)
        let combinedLoading = SignalProducer.combineLatest(infoLoading, playerUnavailable, playerLoading).map({ $0 || $1 || $2 })
        self.loading = Property<Bool>(initial: false, then: combinedLoading)
        
        super.init(nibName: nil, bundle: nil)
        
        self.player.producer
            .observe(on: UIScheduler())
            .startWithValues { [weak playerView] (player: AVPlayer?) in
                playerView?.player = player
            }
        
        // TODO: may have to account for player error state to detect stale URL
        SignalProducer.combineLatest(player.producer, userPlayState.producer, viewState.producer)
            .startWithValues { [weak self] (player: AVPlayer?, userPlayState: UserPlayState, viewState: ViewState) in
                if let player = player {
                    switch (userPlayState, viewState) {
                    case (_, .inactive):
                        player.pause()
                    case (_, .mayBecomeActive):
                        player.pause()
                    case (.play, .active):
                        player.play()
                    case (.pause, .active):
                        player.pause()
                    }
                } else {
                    switch viewState {
                    case .mayBecomeActive, .active:
                        self?.fetchAction.apply(()).start()
                    case .inactive:
                        break
                    }
                }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingView.color = Color.gray60
        
        view |+| [
            playerView,
            loadingView,
            descriptionView
        ]
        
        [playerView, descriptionView] |=| view
        loadingView.m_center |=| view
        
        descriptionView.viewData = VideoDescriptionViewData(title: videoInfo.title, description: videoInfo.description)
        
        descriptionView.alpha = 0
        
        userPlayState.producer
            .startWithValues { [unowned descriptionView] (playState: UserPlayState) in
                let toAlpha: CGFloat = {
                    switch playState {
                    case .play: return 0
                    case .pause: return 1
                    }
                }()
                UIView.animate(withDuration: 0.2, animations: { 
                    descriptionView.alpha = toAlpha
                })
            }
        
        loading.producer
            .startWithValues { [weak loadingView] (isLoading: Bool) in
                isLoading ? loadingView?.startAnimating() : loadingView?.stopAnimating()
            }
    }
}
