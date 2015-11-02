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
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        self.tableView.remembersLastFocusedIndexPath = true
        view.addSubview(self.tableView)
        
        self.eventPreviewView = EventPreviewView()
        view.addSubview(self.eventPreviewView)
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
        
        // TODO: align tableview right, align image above description on the left
        self.backgroundView?.frame = self.view.bounds
        self.eventPreviewView?.frame = CGRect(x: hMargin, y: vMargin + vTopLayoutGuide, width: hPreviewWidth, height: vPreviewHeight)
        self.tableView?.frame = CGRect(x: hMargin + hPreviewWidth + hInterMargin, y: vMargin + vTopLayoutGuide, width: hTableWidth, height:vTableHeight)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadViewModels(accountId, completeBlock: { (result) -> Void in
            self.handleResultOrPresentError(result, block: { (value) -> Void in
                let oldModels = self.viewModels?.map({ $0.model }) ?? []
                let newModels = value.map({ $0.model })
                if (oldModels == newModels) { return }
                self.viewModels = value
                self.tableView?.reloadData()
            })
        })
    }
    
    // MARK: Private
    
    private func loadViewModels(accountId: Int, completeBlock: (result: Result<[EventViewModel], EventError>) -> Void) {
        fetchEventViewModelsForAccount(accountId) { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        }
    }
    
    private func loadEventDetail(eventId: Int, accountId: Int, completeBlock: (result : Result<Event, EventError>) -> Void ) {
        fetchEventDetail(eventId, accountId: accountId, completeBlock: { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        })
    }
    
    private func loadStreamUrlForViewModel(viewModel: EventViewModel, completeBlock: (result: Result<EventViewModel, EventError>) -> Void ) {
        fetchStreamUrlForViewModel(viewModel, completeBlock: { (result) -> Void in
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
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK".l10(), style: .Cancel, handler: { _ -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func presentFullScreenPlayerWithPlayer(player: AVPlayer) {
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        self.presentViewController(playerController, animated: true, completion: { () -> Void in
            player.play()
        })
    }
    
    private func presentFullScreenPlayerWithUrl(url: NSURL) {
        let player = AVPlayer(URL: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        self.presentViewController(playerController, animated: true, completion: { () -> Void in
            player.play()
        })
    }
    
    private func loadImageAndStreamForFocusedIndexPath(focusedIndexPath: NSIndexPath) {
        guard let focusedViewModel: EventViewModel = self.viewModels?[focusedIndexPath.row] else { return }
        loadImageDataForViewModel(focusedViewModel) { [unowned self] (result) -> Void in
            if let imageableViewModel = result.value {
                if focusedViewModel != imageableViewModel {
                    self.viewModels?[focusedIndexPath.row] = imageableViewModel
                    self.updateDetailViewsForFocusedIndexPath()
                }
            }
            
            let maybeViewModel = result.value ?? focusedViewModel
            
            self.loadStreamUrlForViewModel(maybeViewModel, completeBlock: { [unowned self] (result) -> Void in
                if let playableViewModel = result.value {
                    if playableViewModel != maybeViewModel {
                        self.viewModels?[focusedIndexPath.row] = playableViewModel
                        self.updateDetailViewsForFocusedIndexPath()
                    }
                }
            })
        }
    }
    
    private func updateDetailViewsForFocusedIndexPath() {
        guard let index = self.focusedIndexPath?.row else { return }
        let viewModel = self.viewModels?[index]
        // if self.eventPreviewView.viewModel == viewModel { return }
        self.eventPreviewView.viewModel = viewModel
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(UITableViewCell.self), forIndexPath: indexPath)
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let viewModels = viewModels else { return }
        let index = indexPath.item
        
        let viewModel = viewModels[index]
        cell.textLabel?.text = viewModel.title
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO: Make two code paths - one for stream already loaded, one to fetch stream
        guard let model = self.viewModels?[indexPath.row].model else { return }
        let streamName = model.fullName ?? "stream"
        let title = String.localizedStringWithFormat("Loading %@...", streamName)
        
        let alertView = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        self.presentViewController(alertView, animated: true) { () -> Void in
            self.loadEventDetail(model.id, accountId: self.accountId, completeBlock: { (result) -> Void in
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
        self.focusedIndexPath = context.nextFocusedIndexPath
        guard let indexPath = context.nextFocusedIndexPath else { return }
        self.loadImageAndStreamForFocusedIndexPath(indexPath)
        self.updateDetailViewsForFocusedIndexPath()
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
