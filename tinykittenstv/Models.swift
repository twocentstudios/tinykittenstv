//
//  Created by Christopher Trott on 10/6/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Gloss

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
    let imageUrl: NSURL?
    let streamUrl: NSURL?
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
            self.imageUrl = "url" <~~ logo
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