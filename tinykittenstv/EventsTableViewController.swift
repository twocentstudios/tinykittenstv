//
//  Created by Christopher Trott on 10/30/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit
import AVKit
import Result

class EventsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Properties
    
    fileprivate var viewModels: [EventViewModel]?
    fileprivate var focusedIndexPath: IndexPath?
    let accountId: Int
    
    fileprivate var backgroundView: UIImageView!
    fileprivate var tableView: UITableView!
    fileprivate var eventPreviewView: EventPreviewView!
    
    // MARK: UIViewController
    
    init(accountId: Int) {
        self.accountId = accountId
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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
        
        self.tableView = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(ImageTitleDescriptionCell.self, forCellReuseIdentifier: NSStringFromClass(ImageTitleDescriptionCell.self))
        self.tableView.remembersLastFocusedIndexPath = true
        self.tableView.rowHeight = 140
        view.addSubview(self.tableView)
        
        self.eventPreviewView = EventPreviewView()
        view.addSubview(self.eventPreviewView)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] _ in
            self?.conditionallyLoadViewModelsIntoTableView()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let viewWidth: CGFloat = self.view.bounds.width
        let viewHeight: CGFloat = self.view.bounds.height
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.conditionallyLoadViewModelsIntoTableView()
    }
    
    // MARK: Private
    
    fileprivate func conditionallyLoadViewModelsIntoTableView() {
        self.loadViewModels(accountId, completeBlock: { (result) -> Void in
            self.handleResultOrPresentError(result, block: { (value) -> Void in
                let oldModels = self.viewModels?.map({ $0.model }) ?? []
                let newModels = value.map({ $0.model })
                if !(oldModels =~= newModels) {
                    self.viewModels = value
                    self.tableView?.reloadData()
                }
                
                for viewModel in value {
                    guard let index = value.index(of: viewModel) else { return }
                    let indexPath = IndexPath(row: index, section: 0)
                    self.loadImageAndStreamForIndexPath(indexPath)
                }
            })
        })
    }
    
    fileprivate func loadViewModels(_ accountId: Int, completeBlock: @escaping (_ result: Result<[EventViewModel], EventError>) -> Void) {
        fetchEventViewModelsForAccount(accountId) { (result) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                completeBlock(result)
            })
        }
    }
    
    fileprivate func loadDetailForViewModel(_ viewModel: EventViewModel, completeBlock: @escaping (_ result: Result<EventViewModel, EventError>) -> Void ) {
        fetchDetailForViewModel(viewModel, completeBlock: { (result) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                completeBlock(result)
            })
        })
    }
    
    // get image data
    fileprivate func loadImageDataForViewModel(_ viewModel: EventViewModel, completeBlock: @escaping (_ result: Result<EventViewModel, EventError>) -> Void ) {
        fetchImageDataForViewModel(viewModel) { (result) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                completeBlock(result)
            })
        }
    }
    
    fileprivate func handleResultOrPresentError<T>(_ result: Result<T, EventError>, block: (_ value : T) -> Void) {
        if let error = result.error {
            self.presentError(error)
        } else {
            block(result.value!)
        }
    }
    
    fileprivate func presentError(_ error: EventError) {
        print("Error: \(error)")
        let message = error.localizedDescription()
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".l10(), style: .cancel, handler: { _ -> Void in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func presentFullScreenPlayerWithUrl(_ url: URL) {
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        self.present(playerController, animated: true, completion: { () -> Void in
            player.play()
        })
    }
    
    fileprivate func loadImageAndStreamForIndexPath(_ focusedIndexPath: IndexPath) {
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
                self.tableView.reloadRows(at: [focusedIndexPath], with: .fade)
            })
        }
    }
    
    fileprivate func updateDetailViewsForFocusedIndexPath() {
        let index = self.focusedIndexPath?.row
        let viewModel = (index != nil) ? self.viewModels?[index!] : nil
        self.eventPreviewView.viewModel = viewModel
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ImageTitleDescriptionCell.self), for: indexPath)
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ImageTitleDescriptionCell else { fatalError("Expected to display a `ImageTitleDescriptionCell`.") }
        let viewModel = self.viewModels?[indexPath.row]
        cell.viewModel = viewModel
        if (viewModel != nil) {
            cell.playButtonTapGestureBlock = ( { [unowned self] () -> Void in
                self.tableView(self.tableView, didSelectRowAt: indexPath)
            })
        } else {
            cell.playButtonTapGestureBlock = nil
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel: EventViewModel = self.viewModels?[indexPath.row] else { return }
        
        // `streamUrl` may have expired, so always fetch the latest `streamUrl` each full screen request.
        // if let streamUrl = viewModel.streamUrl {
        //    self.presentFullScreenPlayerWithUrl(streamUrl)
        //    return
        // }
        
        let title = String.localizedStringWithFormat("Loading %@...", viewModel.title)
        
        let alertView = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        self.present(alertView, animated: true) { () -> Void in
            self.loadDetailForViewModel(viewModel, completeBlock: { (result) -> Void in
                self.dismiss(animated: true, completion: { () -> Void in
                    if let e = result.error {
                        self.presentError(e)
                        return
                    }
                    
                    guard let streamUrl = result.value!.streamUrl else {
                        self.presentError(EventError.streamURLMissing)
                        return
                    }
                    
                    self.presentFullScreenPlayerWithUrl(streamUrl as URL)
                })
            })
        }
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if self.focusedIndexPath == context.nextFocusedIndexPath { return }
        if (context.nextFocusedIndexPath != nil || !self.eventPreviewView.isFocused) {
            self.focusedIndexPath = context.nextFocusedIndexPath
            self.updateDetailViewsForFocusedIndexPath()
        }
    }

    override var preferredFocusedView: UIView? {
        get {
            return self.tableView
        }
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
    }

}
