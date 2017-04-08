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
import ReactiveCocoa
import Result

enum PageViewData {
    case unloaded
    case loading
    case loaded([LiveVideoInfo])
    case empty
    case failed(NSError)
}

enum UserPlayState {
    case pause
    case play
    
    func toggle() -> UserPlayState {
        switch self {
        case .play: return .pause
        case .pause: return .play
        }
    }
}

final class PageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    let channelId: String
    let sessionConfig: SessionConfig
    let client: XCDYouTubeClient
    
    let viewData: Property<PageViewData>
    let userPlayState = MutableProperty(UserPlayState.play)
    
    let fetchAction: Action<(), LiveVideosSearchResult, NSError>
    
    init(channelId: String, sessionConfig: SessionConfig, client: XCDYouTubeClient) {
        self.channelId = channelId
        self.sessionConfig = sessionConfig
        self.client = client
        
        fetchAction = Action { _ -> SignalProducer<LiveVideosSearchResult, NSError> in
            return Controller.fetchLiveVideos(channelId: channelId, config: sessionConfig)
                .start(on: QueueScheduler())
        }
    
        let loadings = fetchAction.isExecuting.signal.filter({ $0 }).map({ _ in PageViewData.loading })
        let errors = fetchAction.errors.map { PageViewData.failed($0) }
        let values = fetchAction.values.map { $0.liveVideos.count == 0 ? PageViewData.empty : PageViewData.loaded($0.liveVideos) }
        let merged = SignalProducer([loadings, errors, values]).flatten(.merge)
        self.viewData = ReactiveSwift.Property(initial: .unloaded, then: merged)
        
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        self.delegate = self
        self.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundView = UIImageView(image: UIImage(named: "LaunchImage"))
        self.view.addSubview(backgroundView)
        self.view.sendSubview(toBack: backgroundView)
        
        let playButtonTapGesture = UITapGestureRecognizer()
        playButtonTapGesture.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue as Int), NSNumber(value: UIPressType.select.rawValue as Int)];
        self.view.addGestureRecognizer(playButtonTapGesture)
        
        viewData.producer
            // TODO: isEqual
            .observe(on: UIScheduler())
            .startWithValues { [weak self] (viewData: PageViewData) in
                switch viewData {
                case .unloaded:
                    break
                case .empty:
                    let vc = InfoViewController(.normal("No streams are currently active."))
                    self?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                case .loading:
                    let vc = InfoViewController(.normal("Loading..."))
                    self?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                case .failed(let error):
                    let vc = InfoViewController(.error(error.localizedDescription))
                    self?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                case .loaded(let liveVideoInfos):
                    guard let firstVideoInfo = liveVideoInfos.first else { return }
                    guard let this = self else { return }
                    let vc = VideoViewController(videoInfo: firstVideoInfo, client: this.client)
                    this.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                    vc.viewState.swap(.active)
                }
            }
        
        playButtonTapGesture.reactive.stateChanged
            .filterMap({ (gesture: UITapGestureRecognizer) -> ()? in
                return gesture.state == .recognized ? () : nil
            })
            .observeValues { [weak userPlayState] _ in
                guard let userPlayState = userPlayState else { return }
                userPlayState.value = userPlayState.value.toggle()
            }
        
        userPlayState.producer
            .observe(on: UIScheduler())
            .startWithValues { [weak self] (userPlayState: UserPlayState) in
                if let currentVideoViewController = self?.viewControllers?.first as? VideoViewController  {
                    currentVideoViewController.userPlayState.swap(userPlayState)
                }
            }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchAction.apply(()).start()
    }
    
    private func videoInfoAfter(_ videoInfo: LiveVideoInfo) -> LiveVideoInfo? {
        switch viewData.value {
        case .loaded(let infos):
            guard let index = videoInfoIndex(videoInfo) else { return nil }
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
        switch viewData.value {
        case .loaded(let infos):
            guard let index = videoInfoIndex(videoInfo) else { return nil }
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
    
    private func videoInfoIndex(_ videoInfo: LiveVideoInfo) -> Int? {
        switch viewData.value {
        case .loaded(let infos):
            guard let index = infos.index(where: { $0.id == videoInfo.id }) else { return nil }
            return index
        default:
            return nil
        }
    }
    
    private func videoInfoCount() -> Int {
        switch viewData.value {
        case .loaded(let infos): return infos.count
        default: return 0
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let videoViewController = viewController as? VideoViewController else { return nil }
        let videoInfo = videoViewController.videoInfo
        guard let nextVideoInfo = videoInfoAfter(videoInfo) else { return nil }
        let newViewController = VideoViewController(videoInfo: nextVideoInfo, client: client)
        newViewController.viewState.swap(.inactive)
        newViewController.userPlayState.swap(userPlayState.value)
        return newViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let videoViewController = viewController as? VideoViewController else { return nil }
        let videoInfo = videoViewController.videoInfo
        guard let previousVideoInfo = videoInfoBefore(videoInfo) else { return nil }
        let newViewController = VideoViewController(videoInfo: previousVideoInfo, client: client)
        newViewController.viewState.swap(.inactive)
        newViewController.userPlayState.swap(userPlayState.value)
        return newViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let videoViewController = pendingViewControllers.first as? VideoViewController else { return }
        videoViewController.viewState.swap(.mayBecomeActive)
        videoViewController.userPlayState.swap(userPlayState.value)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let previousVideoViewController = previousViewControllers.first as? VideoViewController {
            previousVideoViewController.viewState.swap(.inactive)
            previousVideoViewController.userPlayState.swap(userPlayState.value)
        }
        
        if let currentVideoViewController = self.viewControllers?.first as? VideoViewController  {
            currentVideoViewController.viewState.swap(.active)
            currentVideoViewController.userPlayState.swap(userPlayState.value)
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return videoInfoCount()
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let videoViewController = viewControllers?.first as? VideoViewController else { return 0 }
        guard let index = videoInfoIndex(videoViewController.videoInfo) else { return 0 }
        return index
    }

}

final class VideoViewController: UIViewController {
 
    enum ViewState {
        case inactive
        case mayBecomeActive
        case active
    }
    
    let client: XCDYouTubeClient
    let videoInfo: LiveVideoInfo
    
    lazy var playerView: PlayerView = PlayerView()
    
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
        
        view.addSubview(playerView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        playerView.frame = view.bounds
    }
}

final class InfoViewController: UIViewController {
    enum ViewData {
        case normal(String)
        case error(String)
    }
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title2)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    let viewData: ViewData
    
    init(_ viewData: ViewData) {
        self.viewData = viewData
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view |+| [ infoLabel ]
        infoLabel |=| view.m_edges ~ (80, 80, 80, 80)
        
        switch viewData {
        case .normal(let text):
            infoLabel.text = text
            infoLabel.textColor = UIColor.black
        case .error(let text):
            infoLabel.text = text
            infoLabel.textColor = UIColor.red
        }
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
