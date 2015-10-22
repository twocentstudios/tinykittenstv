//
//  Event.swift
//  livestream
//
//  Created by Christopher Trott on 10/6/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Gloss

// http://api.new.livestream.com/accounts/4175709/events
// http://api.new.livestream.com/accounts/4175709/events/4325133
public struct Event : Decodable {
    let id : Int
    let shortName : String?
    let fullName : String?
    let description : String?
    let isLive : Bool?
    let imageUrl : NSURL?
    let streamUrl : NSURL?
    
    public init?(json: JSON) {
        guard let id: Int = "id" <~~ json else { return nil }
        
        self.id = id
        self.shortName = "short_name" <~~ json
        self.fullName = "full_name" <~~ json
        self.description = "description" <~~ json
        self.isLive = "in_progress" <~~ json
        
        if let logo : JSON = "logo" <~~ json {
            self.imageUrl = "url" <~~ logo
        } else {
            self.imageUrl = nil
        }
       
        if let streamInfo : JSON = "stream_info" <~~ json {
            self.streamUrl = "secure_m3u8_url" <~~ streamInfo
        } else {
            self.streamUrl = nil
        }
    }
}

public struct EventsResponse : Decodable {
    let events : [Event]
    
    public init?(json : JSON) {
        guard let events : [Event] = "data" <~~ json else { return nil }
    
        self.events = events
    }
}