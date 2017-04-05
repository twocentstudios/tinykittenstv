//
//  MainViewController.swift
//  tinykittenstv
//
//  Created by Christopher Trott on 4/4/17.
//  Copyright © 2017 twocentstudios. All rights reserved.
//

import UIKit
import AVKit
import XCDYouTubeKit
import ReactiveSwift
import Result

enum PageViewData {
    case unloaded
    case loading
    case loaded([LiveVideoInfo])
    case errored(NSError)
}

final class PageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    let channelId: String
    let sessionConfig: SessionConfig
    let client: XCDYouTubeClient
    var viewData: PageViewData
    
    init(channelId: String, sessionConfig: SessionConfig, client: XCDYouTubeClient) {
        self.channelId = channelId
        self.sessionConfig = sessionConfig
        self.client = client
        
        self.viewData = PageViewData.unloaded
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.red
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Controller.fetchLiveVideos(channelId: channelId, config: sessionConfig)
            .start(on: QueueScheduler())
            .observe(on: UIScheduler())
            .startWithResult { [weak self] (result: Result<LiveVideosSearchResult, NSError>) in
                guard let this = self else { return }
                switch result {
                case .success(let searchResult):
                    let liveVideos = searchResult.liveVideos
                    this.viewData = .loaded(liveVideos)
                    guard let firstVideoInfo = liveVideos.first else { return }
                    let videoViewController = VideoViewController(videoInfo: firstVideoInfo, client: this.client)
                    this.setViewControllers([videoViewController], direction: .forward, animated: true, completion: nil)
                    videoViewController.loadVideo()
                    videoViewController.playVideo()
                case .failure(let error):
                    this.viewData = .errored(error)
                }
            }
        
        
    }
    
    private func videoInfoAfter(_ videoInfo: LiveVideoInfo) -> LiveVideoInfo? {
        switch viewData {
        case .loaded(let infos):
            guard let index = infos.index(where: { $0.id == videoInfo.id }) else { return nil }
            let nextIndex = index + 1
            if infos.indices.contains(nextIndex) {
                return infos[nextIndex]
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    private func videoInfoBefore(_ videoInfo: LiveVideoInfo) -> LiveVideoInfo? {
        switch viewData {
        case .loaded(let infos):
            guard let index = infos.index(where: { $0.id == videoInfo.id }) else { return nil }
            let nextIndex = index - 1
            if infos.indices.contains(nextIndex) {
                return infos[nextIndex]
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let videoViewController = viewController as? VideoViewController else { return nil }
        let videoInfo = videoViewController.videoInfo
        guard let nextVideoInfo = videoInfoAfter(videoInfo) else { return nil }
        let newViewController = VideoViewController(videoInfo: nextVideoInfo, client: client)
        return newViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let videoViewController = viewController as? VideoViewController else { return nil }
        let videoInfo = videoViewController.videoInfo
        guard let previousVideoInfo = videoInfoBefore(videoInfo) else { return nil }
        let newViewController = VideoViewController(videoInfo: previousVideoInfo, client: client)
        return newViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let videoViewController = pendingViewControllers.first as? VideoViewController else { return }
        videoViewController.loadVideo()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let previousVideoViewController = previousViewControllers.first as? VideoViewController {
            previousVideoViewController.stopVideo()
        }
        
        if let currentVideoViewController = self.viewControllers?.first as? VideoViewController  {
            currentVideoViewController.playVideo()
        }
    }
}

final class VideoViewController: AVPlayerViewController {
    
    let client: XCDYouTubeClient
    let videoInfo: LiveVideoInfo
    private var playWhenReady: Bool = false
    
    init(videoInfo: LiveVideoInfo, client: XCDYouTubeClient) {
        self.videoInfo = videoInfo
        self.client = client
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadVideo() {
        client.rac_getVideoWithIdentifier(videoInfo.id)
            .startWithResult { [weak self] (result: Result<XCDYouTubeVideo, NSError>) in
                guard let this = self else { return }
                guard let streamUrl = result.value?.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] else { return }
                let player = AVPlayer(url: streamUrl)
                this.player = player
                if this.playWhenReady == true {
                    player.play()
                }
            }
    }
    
    func playVideo() {
        guard let player = self.player else {
            self.playWhenReady = true
            return
        }
        player.play()
    }
    
    func stopVideo() {
        self.player?.pause()
    }
}

final class MainViewController: UIViewController {
    
    lazy var playerView: PlayerView = PlayerView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func pause() {
        
    }
}

final class CollectionViewController: UICollectionViewController {
    
    private let videos: [LiveVideoInfo]
    private weak var delegate: NSObject?
    
    init(videos: [LiveVideoInfo], initialSelectedIndex: Int) {
        // TODO: check bounds of initialSelectedIndex
        
        self.videos = videos
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 700, height: 700)
        layout.minimumInteritemSpacing = 40
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionView = self.collectionView!
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(VideoDescriptionCell.self, forCellWithReuseIdentifier: VideoDescriptionCell.reuseIdentifier)
        
        collectionView.backgroundColor = UIColor.clear
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = videos[indexPath.item]
        // delegate
    }
}

struct VideoDescriptionViewData {
    let title: String
    let description: String
}

import Mortar

final class VideoDescriptionCell: UICollectionViewCell {
    
    static let reuseIdentifier = String(describing: VideoDescriptionCell.self)
    
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    
    var viewData: VideoDescriptionViewData? {
        didSet {
            titleLabel.text = viewData?.title
            descriptionLabel.text = viewData?.description
            self.setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.textAlignment = .center
        descriptionLabel.textAlignment = .center
        
        titleLabel.numberOfLines = 0
        descriptionLabel.numberOfLines = 0
        
        contentView |+| [
            titleLabel,
            descriptionLabel
        ]
        
        titleLabel.m_top |=| contentView.m_top
        descriptionLabel.m_top |=| titleLabel.m_bottom + 20
        descriptionLabel.m_bottom |=| contentView.m_bottom
        [titleLabel.m_leading, titleLabel.m_trailing] |=| [contentView.m_leading + 10, contentView.m_trailing + 10]
        [descriptionLabel.m_leading, descriptionLabel.m_trailing] |=| [contentView.m_leading + 10, contentView.m_trailing + 10]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        viewData = nil
    }
}

import AVFoundation

final class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
