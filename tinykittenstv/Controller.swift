//
//  Created by Christopher Trott on 10/21/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import Marshal

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
