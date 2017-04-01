//
//  Created by Christopher Trott on 10/21/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Gloss
import ReactiveSwift
import Result
import Marshal

let BASE_URL = "https://api.new.livestream.com"
let TIMEOUT_INTERVAL = 5.0

// MARK: Public

struct SessionConfig {
    let configuration: URLSessionConfiguration
    let apiKey: String
}

struct Controller {
    static func fetchLiveVideos(channelId: String, config: SessionConfig) -> SignalProducer<LiveVideosSearchResult, NSError> {
        let urlSession = URLSession(configuration: config.configuration)
        let queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "channelId", value: channelId),
            URLQueryItem(name: "eventType", value: "live"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "50"),
            URLQueryItem(name: "key", value: config.apiKey)
        ]
        let urlString = "https://www.googleapis.com/youtube/v3/search"
        var url = URLComponents(string: urlString)!
        url.queryItems = queryItems
        let request = URLRequest(url: url.url!)
        return urlSession.reactive.data(with: request).mapError(toNSError)
            .attemptMap({ (t: (Data, URLResponse)) -> Result<LiveVideosSearchResult, NSError> in
                do {
                    let json: MarshaledObject = try JSONSerialization.jsonObject(with: t.0, options: []) as! MarshaledObject
                    let searchResult = try LiveVideosSearchResult(object: json)
                    return Result<LiveVideosSearchResult, NSError>(value: searchResult)
                } catch let error {
                    return Result<LiveVideosSearchResult, NSError>(error: error as NSError)
                }
            })
    }
}

public func fetchTitleForAccount(_ accountId: Int, completeBlock: @escaping (_ result: Result<String, EventError>) -> Void) {
    let url = URL(string: "\(BASE_URL)/accounts/\(accountId)")!
    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: TIMEOUT_INTERVAL)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(Result<String, EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value! as NSData)
        if let error = jsonResult.error {
            completeBlock(Result<String, EventError>(error: error))
            return
        }
        
        guard let fullName = jsonResult.value!["full_name"] as? String else {
            completeBlock(Result<String, EventError>(error: EventError.invalidResponse))
            return
        }
        
        completeBlock(Result<String, EventError>(value: fullName))
    }
}

public func fetchEventViewModelsForAccount(_ accountId: Int, completeBlock: @escaping (_ result: Result<[EventViewModel], EventError>) -> Void) {
    let url = URL(string: "\(BASE_URL)/accounts/\(accountId)/events")!
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TIMEOUT_INTERVAL)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(Result<[EventViewModel], EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value! as NSData)
        if let error = jsonResult.error {
            completeBlock(Result<[EventViewModel], EventError>(error: error))
            return
        }
        
        guard let eventsResponse = EventsResponse(json: jsonResult.value!) else {
            completeBlock(Result<[EventViewModel], EventError>(error: EventError.invalidResponse))
            return
        }
        
        let events : [Event] = eventsResponse.events
        let eventViewModels =
            events
                .sorted(by: { (e1: Event, e2: Event) -> Bool in e1.id > e2.id })
                .map({ (e: Event) -> EventViewModel in return EventViewModel(model: e, imageData: nil) })
        completeBlock(Result<[EventViewModel], EventError>(value: eventViewModels))
    }
}

public func fetchDetailForViewModel(_ viewModel: EventViewModel, completeBlock: @escaping (_ result : Result<EventViewModel, EventError>) -> Void ) {
    let url = URL(string: "\(BASE_URL)/accounts/\(viewModel.model.accountId)/events/\(viewModel.model.id)")!
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TIMEOUT_INTERVAL)
    fetchDataForRequest(request) { (result) -> Void in
        if let error = result.error {
            completeBlock(Result<EventViewModel, EventError>(error: error))
            return
        }
        
        let jsonResult : Result<JSON, EventError> = parseJSONFromData(result.value! as NSData)
        if let error = jsonResult.error {
            completeBlock(Result<EventViewModel, EventError>(error: error))
            return
        }
        
        guard let event = Event(json: jsonResult.value!) else {
            completeBlock(Result<EventViewModel, EventError>(error: EventError.invalidResponse))
            return
        }
        
        let newEventViewModel = EventViewModel(model: event, imageData: viewModel.imageData)
        
        completeBlock(Result<EventViewModel, EventError>(value: newEventViewModel))
    }
}


public func fetchImageDataForViewModel(_ viewModel: EventViewModel, completeBlock: @escaping (_ result: Result<EventViewModel, EventError>) -> Void ) {
    let imageable = viewModel as Imageable
    if imageable.isLoaded() {
        completeBlock(Result<EventViewModel, EventError>(value: viewModel))
        return
    }
    
    guard let imageUrl = viewModel.model.imageUrl else {
        completeBlock(Result<EventViewModel, EventError>(error: EventError.imageURLMissing))
        return
    }
    
    fetchImageAtURL(imageUrl as URL) { (result) -> Void in
        if let error = result.error {
            completeBlock(Result<EventViewModel, EventError>(error: error))
            return
        }
        
        let newViewModel = EventViewModel(model: viewModel.model, imageData: result.value!)
        completeBlock(Result<EventViewModel, EventError>(value: newViewModel))
    }
}

public func fetchImageAtURL(_ url: URL, completeBlock: @escaping (_ result : Result<Data, EventError>) -> Void ) {
    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: TIMEOUT_INTERVAL)
    fetchDataForRequest(request) { (result) -> Void in
        completeBlock(result)
    }
}

// MARK: Helpers

private func parseJSONFromData(_ data: NSData, opt: JSONSerialization.ReadingOptions = []) -> Result<JSON, EventError> {
    do {
        guard let json = try JSONSerialization.jsonObject(with: data as Data, options: opt) as? JSON else {
            return Result<JSON, EventError>(error: EventError.invalidResponse)
        }
        return Result<JSON, EventError>(value: json)
    } catch let e as NSError {
        return Result<JSON, EventError>(error: EventError.underlyingError(error: e))
    }
}

private func fetchDataForRequest(_ request: URLRequest, completeBlock: @escaping (_ result: Result<Data, EventError>) -> Void) {
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data : Data?, response : URLResponse?, error : NSError?) -> Void in
        if let error = error {
            completeBlock(Result<Data, EventError>(error: EventError.underlyingError(error: error)))
            return
        }
        
        if let data = data {
            completeBlock(Result<Data, EventError>(value: data))
            return
        }
            
        completeBlock(Result<Data, EventError>(error: EventError.unknownError))
    } as! (Data?, URLResponse?, Error?) -> Void) 
    task.resume()
}
