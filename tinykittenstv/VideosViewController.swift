//
//  VideosViewController.swift
//  tinykittenstv
//
//  Created by Christopher Trott on 4/4/17.
//  Copyright © 2017 twocentstudios. All rights reserved.
//

import UIKit
import XCDYouTubeKit
import ReactiveSwift
import ReactiveCocoa
import Result

final class VideosViewController: UIPageViewController {
    
    enum ViewData {
        case unloaded
        case loading
        case loaded([LiveVideoInfo])
        case empty
        case failed(NSError)
    }
    
    let channelId: String
    let sessionConfig: SessionConfig
    let client: XCDYouTubeClient
    
    let viewData: Property<ViewData>
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
    
        let loadings = fetchAction.isExecuting.signal.filter({ $0 }).map({ _ in ViewData.loading })
        let errors = fetchAction.errors.map { ViewData.failed($0) }
        let values = fetchAction.values.map { $0.liveVideos.count == 0 ? ViewData.empty : ViewData.loaded($0.liveVideos) }
        let merged = SignalProducer([loadings, errors, values]).flatten(.merge)
        self.viewData = ReactiveSwift.Property(initial: .unloaded, then: merged)
        
        // TODO: move signal outside this class
        NotificationCenter.default.reactive.notifications(forName: NSNotification.Name.UIApplicationDidBecomeActive)
            .skip(first: 1)
            .observeValues { [weak fetchAction] _ in
                fetchAction?.apply(()).start()
            }
        
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
            .skipRepeats()
            .observe(on: UIScheduler())
            .startWithValues { [weak self] (viewData: ViewData) in
                switch viewData {
                case .unloaded:
                    break
                case .empty:
                    let vc = InfoViewController(.normal("No streams are currently active.".l10()))
                    self?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
                case .loading:
                    let vc = InfoViewController(.normal("Loading...".l10()))
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
                    this.flashPageControl()
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
        
        if let pageControl = findPageControl() {
            pageControl.hidesForSinglePage = true
            pageControl.alpha = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchAction.apply(()).start()
    }
    
    private func findPageControl() -> UIPageControl? {
        return self.view.subviews.first(where: { (pageControl: UIView) -> Bool in
            return pageControl is UIPageControl
        }) as? UIPageControl
    }
    
    private func flashPageControl() {
        guard let pageControl = self.findPageControl() else { return }
        pageControl.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            pageControl.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 4, options: [], animations: {
                pageControl.alpha = 0
            })
        }
    }
}

extension VideosViewController {
    fileprivate func videoInfoAfter(_ videoInfo: LiveVideoInfo) -> LiveVideoInfo? {
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
    
    fileprivate func videoInfoBefore(_ videoInfo: LiveVideoInfo) -> LiveVideoInfo? {
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
    
    fileprivate func videoInfoIndex(_ videoInfo: LiveVideoInfo) -> Int? {
        switch viewData.value {
        case .loaded(let infos):
            guard let index = infos.index(where: { $0.id == videoInfo.id }) else { return nil }
            return index
        default:
            return nil
        }
    }
    
    fileprivate func videoInfoCount() -> Int {
        switch viewData.value {
        case .loaded(let infos): return infos.count
        default: return 0
        }
    }
}

extension VideosViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
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

extension VideosViewController.ViewData: Equatable {}
func ==(lhs: VideosViewController.ViewData, rhs: VideosViewController.ViewData) -> Bool {
    switch (lhs, rhs) {
    case (.loaded(let lhsVideos), .loaded(let rhsVideos)) where lhsVideos == rhsVideos: return true
    case (.failed(let lhsError), .failed(let rhsError)) where lhsError == rhsError: return true
    case (.unloaded, .unloaded): return true
    case (.empty, .empty): return true
    case (.loading, .loading): return true
    default: return false
    }
}

