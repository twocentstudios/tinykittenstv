//
//  MenuViewController.swift
//  livestream
//
//  Created by Christopher Trott on 10/6/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit

class EventsViewController: UICollectionViewController {
    // MARK: Properties    
    private var viewModels : [EventViewModel]?
    
    // MARK: UIViewController
    
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Vertical
        layout.itemSize = CGSize(width: 300, height: 533)
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 32.0
        layout.sectionInset = UIEdgeInsets(top: 32.0, left: 32.0, bottom: 32.0, right: 32.0)
        self.init(collectionViewLayout: layout)
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
        
        loadTitle()
        loadViewModels()
    }
    
    // MARK: Private
    
    let accountId = 4175709
    
    private func loadTitle() {
        let url = NSURL(string: "https://api.new.livestream.com/accounts/\(accountId)")!
        let request = NSURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                    self.presentViewController(alert, animated: true, completion: nil)
                })
                return
            }
            
            guard let data = data else { return }
            guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as! NSDictionary else { return }
            guard let fullName = json["full_name"] as? String else { return }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.title = fullName
            })
        }
        task.resume()
    }
    
    private func loadViewModels() {
        let url = NSURL(string: "https://api.new.livestream.com/accounts/\(accountId)/events")!
        let request = NSURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                    self.presentViewController(alert, animated: true, completion: nil)
                })
                return
            }
            
            guard let data = data else { return }
            guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as! NSDictionary else { return }
            guard let eventDictionaries = json["data"] as? Array<NSDictionary> else { return }
            let events = eventDictionaries.map({ (e : NSDictionary ) -> Event in
                let event = Event(id: e["id"] as! Int, shortName: e["short_name"] as? String, fullName: e["full_name"] as? String, description: e["description"] as? String, isLive: e["in_progress"] as? Bool, imageUrl: NSURL(string: (e["logo"]?["url"])! as! String), streamUrl: nil)
                return event
            })
            
            let eventViewModels = events.map({ (e : Event) -> EventViewModel in
                let eventViewModel = EventViewModel(title: e.fullName ?? "No Title", imageData: nil, model: e)
                return eventViewModel
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.viewModels = eventViewModels
                
                self.collectionView?.reloadData()
            })
        }
        task.resume()
    }
    
    private func conditionallyLoadViewModelPropertiesAtIndex(index : Int) {
        guard let viewModel = self.viewModels?[index] else { return }
        if viewModel.imageData != nil { return }
        guard let imageUrl = viewModel.model.imageUrl else { return }
        let request = NSURLRequest(URL: imageUrl)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            if error != nil { return }
            
            guard let data = data else { return }
            let newViewModel = EventViewModel(title: viewModel.title, imageData: data, model: viewModel.model)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.viewModels?[index] = newViewModel
                
                self.collectionView?.performBatchUpdates({ () -> Void in
                    self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
                }, completion: nil)

            })
        }
        task.resume()
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
        
        let viewModel = viewModels[indexPath.row]
        cell.viewModel = viewModel
        
        conditionallyLoadViewModelPropertiesAtIndex(indexPath.item)
    }
}