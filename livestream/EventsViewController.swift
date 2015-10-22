//
//  MenuViewController.swift
//  livestream
//
//  Created by Christopher Trott on 10/6/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit
import AVKit



class EventsViewController: UICollectionViewController {
    // MARK: Properties    
    private var viewModels : [EventViewModel]?
    let accountId : Int
    
    // MARK: UIViewController
    
    init(accountId: Int) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Vertical
        layout.itemSize = CGSize(width: 300, height: 533)
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 32.0
        layout.sectionInset = UIEdgeInsets(top: 32.0, left: 32.0, bottom: 32.0, right: 32.0)
        
        self.accountId = accountId
        super.init(collectionViewLayout: layout)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let collectionView = collectionView else { return }

        collectionView.registerClass(ImageTitleCell.self, forCellWithReuseIdentifier: NSStringFromClass(ImageTitleCell.self))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let collectionView = collectionView else { return }
        
        collectionView.frame = self.view.bounds
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (viewModels == nil) {
            loadTitle(accountId, completeBlock: { [unowned self] (result) -> Void in
                if let error = result.error as? EventError {
                    self.presentError(error)
                } else {
                    self.title = result.value!
                }
            })
            loadViewModels(accountId, completeBlock: { [unowned self] (result) -> Void in
                if let error = result.error as? EventError {
                    self.presentError(error)
                } else {
                    self.viewModels = result.value!
                    self.collectionView?.reloadData()
                }
            })
        }
    }
    
    // MARK: Private aka massive view controller
    private func loadTitle(accountId: Int, completeBlock: (result: Result<String>) -> Void) {
        fetchTitleForAccount(accountId) { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        }
    }
    
    private func loadViewModels(accountId: Int, completeBlock: (result: Result<[EventViewModel]>) -> Void) {
        fetchEventViewModelsForAccount(accountId) { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        }
    }
    
    private func loadEventDetail(eventId: Int, accountId: Int, completeBlock: (result : Result<Event>) -> Void ) {
        fetchEventDetail(eventId, accountId: accountId, completeBlock: { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        })
    }
    
    private func loadFullViewModelForViewModel(viewModel: EventViewModel, completeBlock: (result: Result<EventViewModel>) -> Void ) {
        fetchFullViewModelForViewModel(viewModel) { (result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completeBlock(result: result)
            })
        }
    }
    
    private func presentError(error: EventError) {
        let message = errorMessageForEventError(error)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { _ -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func errorMessageForEventError(error: EventError) -> String {
        switch error {
        case .InvalidResponse:
            return "The server returned an invalid response."
        case .UnderlyingError(let e):
            if let nserror = e as? NSError {
                return nserror.localizedDescription
            } else {
                return "An error occurred."
            }
        default:
            return "An unknown error occurred. Please try again."
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let viewModels = viewModels else { return 0 }
        return viewModels.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(ImageTitleCell.self), forIndexPath: indexPath)
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? ImageTitleCell else { fatalError("Expected to display a `ImageTitleCell`.") }
        guard let viewModels = viewModels else { return }
        let index = indexPath.item
        
        let viewModel = viewModels[index]
        cell.viewModel = viewModel
        
        loadFullViewModelForViewModel(viewModel) { (result) -> Void in
            // Ignore image load errors
            guard let newViewModel = result.value else { return }
            self.viewModels?[index] = newViewModel
            self.collectionView?.performBatchUpdates({ () -> Void in
                self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
            }, completion: nil)
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let model = self.viewModels?[indexPath.row].model else { return }
        let streamName = model.fullName ?? "stream"
        
        let alertView = UIAlertController(title: nil, message: "Loading \(streamName)...", preferredStyle: .Alert)
        self.presentViewController(alertView, animated: true) { () -> Void in
            self.loadEventDetail(model.id, accountId: self.accountId, completeBlock: { (result) -> Void in
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    if let e = result.error as? EventError {
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
}