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

extension LiveVideoInfo: Equatable {}
func ==(lhs: LiveVideoInfo, rhs: LiveVideoInfo) -> Bool {
    return lhs.id == rhs.id &&
        lhs.kind == rhs.kind &&
        lhs.channelId == rhs.channelId &&
        lhs.channelTitle == rhs.channelTitle &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.status == rhs.status
}

// Unused
struct Image {
    let url: URL
    let width: Double
    let height: Double
}

// Unused
struct LiveVideo {
    let info: LiveVideoInfo
    let streamURL: URL
}

