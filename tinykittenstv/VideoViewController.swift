//
//  VideoViewController.swift
//  tinykittenstv
//
//  Created by Christopher Trott on 4/13/17.
//  Copyright © 2017 twocentstudios. All rights reserved.
//

import UIKit
import ReactiveSwift
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
    
    let userPlayState = MutableProperty(UserPlayState.play)
    let viewState = MutableProperty(ViewState.inactive)
    private let player: Property<AVPlayer?>
    
    private let fetchAction: Action<(), XCDYouTubeVideo, NSError>
    
    init(videoInfo: LiveVideoInfo, client: XCDYouTubeClient) {
        self.videoInfo = videoInfo
        self.client = client
        
        fetchAction = Action { _ -> SignalProducer<XCDYouTubeVideo, NSError> in
            return client.rac_getVideoWithIdentifier(videoInfo.id)
                .start(on: QueueScheduler())
        }
        
        // TODO: loading/error?
        // let loadings = fetchAction.isExecuting.signal.filter({ $0 }).map({ _ in ??? })
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
        
        view |+| [
            playerView,
            descriptionView
        ]
        
        [playerView, descriptionView] |=| view
        
        descriptionView.viewData = VideoDescriptionViewData(title: videoInfo.title, description: videoInfo.description)
        
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
    }
}
