//
//  Controller.swift
//  livestream
//
//  Created by Christopher Trott on 10/21/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Gloss

public struct Result<T> {
    let value : T?
    let error : ErrorType?
    
    init(value: T) {
        self.value = value
        self.error = nil
    }
    
    init(error: ErrorType) {
        self.error = error
        self.value = nil
    }
}

public enum EventError : ErrorType {
    case UnderlyingError(error: ErrorType)
    case InvalidResponse
    case ImageURLMissing
    case StreamURLMissing
    case UnknownError
}

let BASE_URL = "https://api.new.livestream.com"

public func fetchTitleForAccount(accountId: Int, completeBlock: (result: Result<String>) -> Void) {
    let url = NSURL(string: "\(BASE_URL)/accounts/\(accountId)")!
    let request = NSURLRequest(URL: url)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<String>(error: error))
            return
        }
        
        let jsonResult : Result<JSON> = parseJSONFromData(result.value!)
        if let error = result.error {
            completeBlock(result: Result<String>(error: EventError.UnderlyingError(error: error)))
            return
        }
        
        guard let fullName = jsonResult.value!["full_name"] as? String else {
            completeBlock(result: Result<String>(error: EventError.InvalidResponse))
            return
        }
        
        completeBlock(result: Result<String>(value: fullName))
    }
}

public func fetchEventViewModelsForAccount(accountId: Int, completeBlock: (result: Result<[EventViewModel]>) -> Void) {
    let url = NSURL(string: "\(BASE_URL)/accounts/\(accountId)/events")!
    let request = NSURLRequest(URL: url)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<[EventViewModel]>(error: error))
            return
        }
        
        let jsonResult : Result<JSON> = parseJSONFromData(result.value!)
        if let error = result.error {
            completeBlock(result: Result<[EventViewModel]>(error: EventError.UnderlyingError(error: error)))
            return
        }
        
        guard let eventsResponse = EventsResponse(json: jsonResult.value!) else {
            completeBlock(result: Result<[EventViewModel]>(error: EventError.InvalidResponse))
            return
        }
        
        let events : [Event] = eventsResponse.events
        let eventViewModels = eventViewModelsForEvents(events)
        completeBlock(result: Result<[EventViewModel]>(value: eventViewModels))
    }
}

public func fetchEventDetail(eventId: Int, accountId: Int, completeBlock: (result : Result<Event>) -> Void ) {
    let url = NSURL(string: "\(BASE_URL)/accounts/\(accountId)/events/\(eventId)")!
    let request = NSURLRequest(URL: url)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<Event>(error: error))
            return
        }
        
        let jsonResult : Result<JSON> = parseJSONFromData(result.value!)
        if let error = result.error {
            completeBlock(result: Result<Event>(error: EventError.UnderlyingError(error: error)))
            return
        }
        
        guard let event = Event(json: jsonResult.value!) else {
            completeBlock(result: Result<Event>(error: EventError.InvalidResponse))
            return
        }
        
        completeBlock(result: Result<Event>(value: event))
    }
}

public func fetchFullViewModelForViewModel(viewModel: EventViewModel, completeBlock: (result: Result<EventViewModel>) -> Void ) {
    if viewModel.isLoaded() { return }
    
    guard let imageUrl = viewModel.model.imageUrl else {
        completeBlock(result: Result<EventViewModel>(error: EventError.ImageURLMissing))
        return
    }
    
    fetchImageAtURL(imageUrl) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result(error: error))
            return
        }
        
        let newViewModel = EventViewModel(title: viewModel.title, imageData: result.value!, model: viewModel.model)
        completeBlock(result: Result<EventViewModel>(value: newViewModel))
    }
}

public func fetchImageAtURL(url: NSURL, completeBlock: (result : Result<NSData>) -> Void ) {
    let request = NSURLRequest(URL: url)
    fetchDataForRequest(request) { (result) -> Void in
        completeBlock(result: result)
    }
}

private func parseJSONFromData(data: NSData, opt: NSJSONReadingOptions = []) -> Result<JSON> {
    do {
        guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: opt) as? JSON else {
            return Result<JSON>(error: EventError.InvalidResponse)
        }
        return Result<JSON>(value: json)
    } catch let e as NSError {
        return Result<JSON>(error: e)
    }
}

private func eventViewModelsForEvents(events: [Event]) -> [EventViewModel] {
    return events.map({ (e : Event) -> EventViewModel in
        let eventViewModel = EventViewModel(title: e.fullName ?? "No Title", imageData: nil, model: e)
        return eventViewModel
    })
}

private func fetchDataForRequest(request: NSURLRequest, completeBlock: (result: Result<NSData>) -> Void) {
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
        if let error = error {
            completeBlock(result: Result<NSData>(error: EventError.UnderlyingError(error: error)))
            return
        }
        
        if let data = data {
            completeBlock(result: Result<NSData>(value: data))
            return
        }
            
        completeBlock(result: Result<NSData>(error: EventError.UnknownError))
    }
    task.resume()
}
