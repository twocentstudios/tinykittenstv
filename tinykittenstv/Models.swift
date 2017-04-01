//
//  Created by Christopher Trott on 10/6/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Gloss
import Marshal


// GET https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=UCeL2LSl91k2VccR7XEh5IKg&eventType=live&type=video&key=YOUR_KEY&maxResults=50
struct LiveVideosSearchResult: Unmarshaling {
    let liveVideos: [LiveVideoInfo]
    
    init(object: MarshaledObject) throws {
        liveVideos = try object.value(for: "items")
    }
}

struct LiveVideo {
    let info: LiveVideoInfo
    let streamURL: URL
}

struct LiveVideoInfo: Unmarshaling {
    enum Status: String {
        case live
        case none
        case upcoming
    }
    
    let id: String
    let kind: String
    // let publishedAt: Date
    let channelId: String
    let channelTitle: String
    let title: String
    let description: String
    // let image: Image
    let status: Status
    
    init(object: MarshaledObject) throws {
        id = try object.value(for: "id.videoId")
        kind = try object.value(for: "id.kind")
        channelId = try object.value(for: "snippet.channelId")
        channelTitle = try object.value(for: "snippet.channelTitle")
        title = try object.value(for: "snippet.title")
        description = try object.value(for: "snippet.description")
        status = try object.value(for: "snippet.liveBroadcastContent")
    }
}

struct Image {
    let url: URL
    let width: Double
    let height: Double
}


// http://api.new.livestream.com/accounts/4175709/events
// http://api.new.livestream.com/accounts/4175709/events/4325133
public struct Event: Decodable {
    let id: Int
    let accountId: Int
    let shortName: String?
    let fullName: String?
    let description: String?
    let isLive: Bool? // determined by streamUrl presence
    let viewerCount: Int?
    let imageUrl: URL?
    let streamUrl: URL?
    let isDetailLoaded: Bool
    
    public init?(json: JSON) {
        guard let id: Int = "id" <~~ json else { return nil }
        guard let accountId: Int = "owner_account_id" <~~ json else { return nil }
        
        self.id = id
        self.accountId = accountId
        self.shortName = "short_name" <~~ json
        self.fullName = "full_name" <~~ json
        self.description = "description" <~~ json
        self.viewerCount = "viewer_count" <~~ json
        
        if let logo: JSON = "logo" <~~ json {
            self.imageUrl = "small_url" <~~ logo
        } else {
            self.imageUrl = nil
        }
       
        if let streamInfo: JSON = "stream_info" <~~ json {
            self.streamUrl = "secure_m3u8_url" <~~ streamInfo
        } else {
            self.streamUrl = nil
        }
        
        // use the "real_time" key as an indicator for whether we're getting the detail results
        if let _: JSON = "real_time" <~~ json {
            self.isDetailLoaded = true
        } else {
            self.isDetailLoaded = false
        }
        
        if self.isDetailLoaded {
            self.isLive = (self.streamUrl != nil)
        } else {
            self.isLive = nil
        }
    }
}

extension Event: Equatable {}
public func ==(lhs: Event, rhs: Event) -> Bool {
    // It could be dangerous to define == as the id param...
    return lhs.id == rhs.id && lhs.isDetailLoaded == rhs.isDetailLoaded
}

extension Event: Identifiable {}
public func =~=(lhs: Event, rhs: Event) -> Bool {
    return lhs.id == rhs.id
}

public struct EventsResponse: Decodable {
    let events : [Event]
    
    public init?(json : JSON) {
        guard let events : [Event] = "data" <~~ json else { return nil }
    
        self.events = events
    }
}
