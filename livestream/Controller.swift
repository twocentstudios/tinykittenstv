//
//  Controller.swift
//  livestream
//
//  Created by Christopher Trott on 10/21/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Gloss

public struct Result<T, E> {
    let value : T?
    let error : E?
    
    init(value: T) {
        self.value = value
        self.error = nil
    }
    
    init(error: E) {
        self.error = error
        self.value = nil
    }
}

public enum EventError : ErrorType {
    case UnderlyingError(error: NSError)
    case InvalidResponse
    case ImageURLMissing
    case StreamURLMissing
    case UnknownError
    
    func localizedDescription() -> String {
        switch self {
        case .InvalidResponse:
            return "The server returned an invalid response.".l10()
        case .StreamURLMissing:
            return "The stream's URL could not be found.".l10()
        case .ImageURLMissing:
            return "The stream's image URL could not be found.".l10()
        case .UnderlyingError(let e):
            return e.localizedDescription
        default:
            return "An unknown error occurred. Please try again.".l10()
        }
    }
}

let BASE_URL = "https://api.new.livestream.com"

public func fetchTitleForAccount(accountId: Int, completeBlock: (result: Result<String, EventError>) -> Void) {
    let url = NSURL(string: "\(BASE_URL)/accounts/\(accountId)")!
    let request = NSURLRequest(URL: url)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<String, EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value!)
        if let error = result.error {
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
    let request = NSURLRequest(URL: url)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<[EventViewModel], EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value!)
        if let error = result.error {
            completeBlock(result: Result<[EventViewModel], EventError>(error: error))
            return
        }
        
        guard let eventsResponse = EventsResponse(json: jsonResult.value!) else {
            completeBlock(result: Result<[EventViewModel], EventError>(error: EventError.InvalidResponse))
            return
        }
        
        let events : [Event] = eventsResponse.events
        let eventViewModels = eventViewModelsForEvents(events)
        completeBlock(result: Result<[EventViewModel], EventError>(value: eventViewModels))
    }
}

public func fetchEventDetail(eventId: Int, accountId: Int, completeBlock: (result : Result<Event, EventError>) -> Void ) {
    let url = NSURL(string: "\(BASE_URL)/accounts/\(accountId)/events/\(eventId)")!
    let request = NSURLRequest(URL: url)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<Event, EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value!)
        if let error = result.error {
            completeBlock(result: Result<Event, EventError>(error: error))
            return
        }
        
        guard let event = Event(json: jsonResult.value!) else {
            completeBlock(result: Result<Event, EventError>(error: EventError.InvalidResponse))
            return
        }
        
        completeBlock(result: Result<Event, EventError>(value: event))
    }
}

public func fetchFullViewModelForViewModel(viewModel: EventViewModel, completeBlock: (result: Result<EventViewModel, EventError>) -> Void ) {
    if viewModel.isLoaded() { return }
    
    guard let imageUrl = viewModel.model.imageUrl else {
        completeBlock(result: Result<EventViewModel, EventError>(error: EventError.ImageURLMissing))
        return
    }
    
    fetchImageAtURL(imageUrl) { (result) -> Void in
        if let error = result.error {
            completeBlock(result: Result<EventViewModel, EventError>(error: error))
            return
        }
        
        let newViewModel = EventViewModel(title: viewModel.title, imageData: result.value!, model: viewModel.model)
        completeBlock(result: Result<EventViewModel, EventError>(value: newViewModel))
    }
}

public func fetchImageAtURL(url: NSURL, completeBlock: (result : Result<NSData, EventError>) -> Void ) {
    let request = NSURLRequest(URL: url)
    fetchDataForRequest(request) { (result) -> Void in
        completeBlock(result: result)
    }
}

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

private func eventViewModelsForEvents(events: [Event]) -> [EventViewModel] {
    return events.map({ (e : Event) -> EventViewModel in
        let eventViewModel = EventViewModel(title: e.fullName ?? "No Title".l10(), imageData: nil, model: e)
        return eventViewModel
    })
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
