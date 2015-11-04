//
//  Created by Christopher Trott on 10/21/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Gloss

let BASE_URL = "https://api.new.livestream.com"
let TIMEOUT_INTERVAL = 5.0

// MARK: Public

public func fetchTitleForAccount(accountId: Int, completeBlock: (result: Result<String, EventError>) -> Void) {
    let url = NSURL(string: "\(BASE_URL)/accounts/\(accountId)")!
    let request = NSURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: TIMEOUT_INTERVAL)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<String, EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value!)
        if let error = jsonResult.error {
            completeBlock(result: Result<String, EventError>(error: error))
            return
        }
        
        guard let fullName = jsonResult.value!["full_name"] as? String else {
            completeBlock(result: Result<String, EventError>(error: EventError.InvalidResponse))
            return
        }
        
        completeBlock(result: Result<String, EventError>(value: fullName))
    }
}

public func fetchEventViewModelsForAccount(accountId: Int, completeBlock: (result: Result<[EventViewModel], EventError>) -> Void) {
    let url = NSURL(string: "\(BASE_URL)/accounts/\(accountId)/events")!
    let request = NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: TIMEOUT_INTERVAL)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<[EventViewModel], EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value!)
        if let error = jsonResult.error {
            completeBlock(result: Result<[EventViewModel], EventError>(error: error))
            return
        }
        
        guard let eventsResponse = EventsResponse(json: jsonResult.value!) else {
            completeBlock(result: Result<[EventViewModel], EventError>(error: EventError.InvalidResponse))
            return
        }
        
        let events : [Event] = eventsResponse.events
        let eventViewModels = events.map({ (e: Event) -> EventViewModel in return EventViewModel(model: e, imageData: nil) })
        completeBlock(result: Result<[EventViewModel], EventError>(value: eventViewModels))
    }
}

public func fetchDetailForViewModel(viewModel: EventViewModel, completeBlock: (result : Result<EventViewModel, EventError>) -> Void ) {
    let url = NSURL(string: "\(BASE_URL)/accounts/\(viewModel.model.accountId)/events/\(viewModel.model.id)")!
    let request = NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: TIMEOUT_INTERVAL)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<EventViewModel, EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value!)
        if let error = jsonResult.error {
            completeBlock(result: Result<EventViewModel, EventError>(error: error))
            return
        }
        
        guard let event = Event(json: jsonResult.value!) else {
            completeBlock(result: Result<EventViewModel, EventError>(error: EventError.InvalidResponse))
            return
        }
        
        let newEventViewModel = EventViewModel(model: event, imageData: viewModel.imageData)
        
        completeBlock(result: Result<EventViewModel, EventError>(value: newEventViewModel))
    }
}


public func fetchImageDataForViewModel(viewModel: EventViewModel, completeBlock: (result: Result<EventViewModel, EventError>) -> Void ) {
    let imageable = viewModel as Imageable
    if imageable.isLoaded() {
        completeBlock(result: Result<EventViewModel, EventError>(value: viewModel))
        return
    }
    
    guard let imageUrl = viewModel.model.imageUrl else {
        completeBlock(result: Result<EventViewModel, EventError>(error: EventError.ImageURLMissing))
        return
    }
    
    fetchImageAtURL(imageUrl) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<EventViewModel, EventError>(error: error))
            return
        }
        
        let newViewModel = EventViewModel(model: viewModel.model, imageData: result.value!)
        completeBlock(result: Result<EventViewModel, EventError>(value: newViewModel))
    }
}

public func fetchImageAtURL(url: NSURL, completeBlock: (result : Result<NSData, EventError>) -> Void ) {
    let request = NSURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: TIMEOUT_INTERVAL)
    fetchDataForRequest(request) { (result) -> Void in
        completeBlock(result: result)
    }
}

// MARK: Helpers

private func parseJSONFromData(data: NSData, opt: NSJSONReadingOptions = []) -> Result<JSON, EventError> {
    do {
        guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: opt) as? JSON else {
            return Result<JSON, EventError>(error: EventError.InvalidResponse)
        }
        return Result<JSON, EventError>(value: json)
    } catch let e as NSError {
        return Result<JSON, EventError>(error: EventError.UnderlyingError(error: e))
    }
}

private func fetchDataForRequest(request: NSURLRequest, completeBlock: (result: Result<NSData, EventError>) -> Void) {
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
        if let error = error {
            completeBlock(result: Result<NSData, EventError>(error: EventError.UnderlyingError(error: error)))
            return
        }
        
        if let data = data {
            completeBlock(result: Result<NSData, EventError>(value: data))
            return
        }
            
        completeBlock(result: Result<NSData, EventError>(error: EventError.UnknownError))
    }
    task.resume()
}
