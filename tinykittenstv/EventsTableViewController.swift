//
//  Created by Christopher Trott on 10/30/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit
import AVKit

class EventsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Properties
    
    private var viewModels: [EventViewModel]?
    private var focusedIndexPath: NSIndexPath?
    let accountId: Int
    
    private var backgroundView: UIImageView!
    private var tableView: UITableView!
    private var eventPreviewView: EventPreviewView!
    
    // MARK: UIViewController
    
    init(accountId: Int) {
        self.accountId = accountId
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "logo-nav-bar"))
        
        guard let view = self.view else { return }
        
        self.backgroundView = UIImageView(image: UIImage(named: "LaunchImage"))
        view.addSubview(self.backgroundView)
        
        self.tableView = UITableView(frame: CGRectZero, style: .Plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.registerClass(ImageTitleDescriptionCell.self, forCellReuseIdentifier: NSStringFromClass(ImageTitleDescriptionCell.self))
        self.tableView.remembersLastFocusedIndexPath = true
        self.tableView.rowHeight = 140
        view.addSubview(self.tableView)
        
        self.eventPreviewView = EventPreviewView()
        view.addSubview(self.eventPreviewView)
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.conditionallyLoadViewModelsIntoTableView()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let viewWidth: CGFloat = CGRectGetWidth(self.view.bounds)
        let viewHeight: CGFloat = CGRectGetHeight(self.view.bounds)
        let vTopLayoutGuide: CGFloat = self.topLayoutGuide.length
        let vMargin: CGFloat = 80
        let hMargin: CGFloat = 100.0
        let hInterMargin: CGFloat = 40.0
        let vTableHeight: CGFloat = viewHeight - vMargin * 2 - vTopLayoutGuide
        let hTableWidth: CGFloat = viewWidth / 2.0 - hMargin - hInterMargin / 2.0
        let vPreviewHeight: CGFloat = vTableHeight
        let hPreviewWidth: CGFloat = hTableWidth
        
        self.backgroundView?.frame = self.view.bounds
        self.eventPreviewView?.frame = CGRect(x: hMargin, y: vMargin + vTopLayoutGuide, width: hPreviewWidth, height: vPreviewHeight)
        self.tableView?.frame = CGRect(x: hMargin + hPreviewWidth + hInterMargin, y: vMargin + vTopLayoutGuide, width: hTableWidth, height:vTableHeight)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.conditionallyLoadViewModelsIntoTableView()
    }
    
    // MARK: Private
    
    private func conditionallyLoadViewModelsIntoTableView() {
        self.loadViewModels(accountId, completeBlock: { (result) -> Void in
            self.handleResultOrPresentError(result, block: { (value) -> Void in
                let oldModels = self.viewModels?.map({ $0.model }) ?? []
                let newModels = value.map({ $0.model })
                if !(oldModels =~= newModels) {
                    self.viewModels = value
                    self.tableView?.reloadData()
                }
                
                for viewModel in value {
                    guard let index = value.indexOf(viewModel) else { return }
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    self.loadImageAndStreamForIndexPath(indexPath)
                }
            })
        })
    }
    
    private func loadViewModels(accountId: Int, completeBlock: (result: Result<[EventViewModel], EventError>) -> Void) {
        fetchEventViewModelsForAccount(accountId) { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        }
    }
    
    private func loadDetailForViewModel(viewModel: EventViewModel, completeBlock: (result: Result<EventViewModel, EventError>) -> Void ) {
        fetchDetailForViewModel(viewModel, completeBlock: { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        })
    }
    
    // get image data
    private func loadImageDataForViewModel(viewModel: EventViewModel, completeBlock: (result: Result<EventViewModel, EventError>) -> Void ) {
        fetchImageDataForViewModel(viewModel) { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        }
    }
    
    private func handleResultOrPresentError<T>(result: Result<T, EventError>, block: (value : T) -> Void) {
        if let error = result.error {
            self.presentError(error)
        } else {
            block(value: result.value!)
        }
    }
    
    private func presentError(error: EventError) {
        print("Error: \(error)")
        let message = error.localizedDescription()
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK".l10(), style: .Cancel, handler: { _ -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func presentFullScreenPlayerWithUrl(url: NSURL) {
        let player = AVPlayer(URL: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        self.presentViewController(playerController, animated: true, completion: { () -> Void in
            player.play()
        })
    }
    
    private func loadImageAndStreamForIndexPath(focusedIndexPath: NSIndexPath) {
        guard let focusedViewModel: EventViewModel = self.viewModels?[focusedIndexPath.row] else { return }
        loadImageDataForViewModel(focusedViewModel) { [unowned self] (result) -> Void in
            if let imageableViewModel = result.value {
                if focusedViewModel != imageableViewModel {
                    self.viewModels?[focusedIndexPath.row] = imageableViewModel
                }
            }
            
            let maybeViewModel = result.value ?? focusedViewModel
            
            self.loadDetailForViewModel(maybeViewModel, completeBlock: { [unowned self] (result) -> Void in
                if let playableViewModel = result.value {
                    if playableViewModel != maybeViewModel {
                        self.viewModels?[focusedIndexPath.row] = playableViewModel
                        self.updateDetailViewsForFocusedIndexPath()
                    }
                }
                self.tableView.reloadRowsAtIndexPaths([focusedIndexPath], withRowAnimation: .Fade)
            })
        }
    }
    
    private func updateDetailViewsForFocusedIndexPath() {
        let index = self.focusedIndexPath?.row
        let viewModel = (index != nil) ? self.viewModels?[index!] : nil
        self.eventPreviewView.viewModel = viewModel
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ImageTitleDescriptionCell.self), forIndexPath: indexPath)
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? ImageTitleDescriptionCell else { fatalError("Expected to display a `ImageTitleDescriptionCell`.") }
        let viewModel = self.viewModels?[indexPath.row]
        cell.viewModel = viewModel
        if (viewModel != nil) {
            cell.playButtonTapGestureBlock = ( { [unowned self] () -> Void in
                self.tableView(self.tableView, didSelectRowAtIndexPath: indexPath)
            })
        } else {
            cell.playButtonTapGestureBlock = nil
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let viewModel: EventViewModel = self.viewModels?[indexPath.row] else { return }
        
        // `streamUrl` may have expired, so always fetch the latest `streamUrl` each full screen request.
        // if let streamUrl = viewModel.streamUrl {
        //    self.presentFullScreenPlayerWithUrl(streamUrl)
        //    return
        // }
        
        let title = String.localizedStringWithFormat("Loading %@...", viewModel.title)
        
        let alertView = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        self.presentViewController(alertView, animated: true) { () -> Void in
            self.loadDetailForViewModel(viewModel, completeBlock: { (result) -> Void in
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    if let e = result.error {
                        self.presentError(e)
                        return
                    }
                    
                    guard let streamUrl = result.value!.streamUrl else {
                        self.presentError(EventError.StreamURLMissing)
                        return
                    }
                    
                    self.presentFullScreenPlayerWithUrl(streamUrl)
                })
            })
        }
    }
    
    func tableView(tableView: UITableView, canFocusRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, shouldUpdateFocusInContext context: UITableViewFocusUpdateContext) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, didUpdateFocusInContext context: UITableViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        if self.focusedIndexPath == context.nextFocusedIndexPath { return }
        if (context.nextFocusedIndexPath != nil || !self.eventPreviewView.focused) {
            self.focusedIndexPath = context.nextFocusedIndexPath
            self.updateDetailViewsForFocusedIndexPath()
        }
    }

    override var preferredFocusedView: UIView? {
        get {
            return self.tableView
        }
    }
    
    override func shouldUpdateFocusInContext(context: UIFocusUpdateContext) -> Bool {
        return true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        
    }

}
