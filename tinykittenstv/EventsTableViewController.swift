//
//  Created by Christopher Trott on 10/30/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit
import AVKit

class EventsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Properties
    
    private var viewModels: [EventViewModel]?
    let accountId: Int
    
    private var tableView: UITableView!
    private var previewImageView: UIImageView!
    private var descriptionLabel: UILabel!
    
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
    
    override func loadView() {
        self.view = UIImageView(image: UIImage(named: "LaunchImage"))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "logo-nav-bar"))
        
        guard let view = self.view else { return }
        
        self.tableView = UITableView(frame: CGRectZero, style: .Plain)
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        self.tableView.remembersLastFocusedIndexPath = true
        view.addSubview(self.tableView)
        
        self.previewImageView = UIImageView()
        self.previewImageView.contentMode = .ScaleAspectFit
        view.addSubview(self.previewImageView)
        
        self.descriptionLabel = UILabel()
        // TODO: styling
        view.addSubview(self.descriptionLabel)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // TODO: align tableview right, align image above description on the left
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
    
    // get image data
    private func loadFullViewModelForViewModel(viewModel: EventViewModel, completeBlock: (result: Result<EventViewModel, EventError>) -> Void ) {
        fetchFullViewModelForViewModel(viewModel) { (result) -> Void in
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
        
        // TODO: move this to the update focus callback
        loadFullViewModelForViewModel(viewModel) { (result) -> Void in
            if let error = result.error { print(error) }
            guard let newViewModel = result.value else { return }
            self.viewModels?[index] = newViewModel
            self.tableView?.beginUpdates()
            self.tableView?.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
            self.tableView?.endUpdates()
        }
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
                    
                    let player = AVPlayer(URL: streamUrl)
                    let playerController = AVPlayerViewController()
                    playerController.player = player
                    
                    self.presentViewController(playerController, animated: true, completion: { () -> Void in
                        player.play()
                    })
                })
            })
        }
    }

    func tableView(tableView: UITableView, shouldUpdateFocusInContext context: UITableViewFocusUpdateContext) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, didUpdateFocusInContext context: UITableViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        // TODO:
        // * fetch event cover image
        // * fetch additional event data
        // * fetch live event image data
    }

}
