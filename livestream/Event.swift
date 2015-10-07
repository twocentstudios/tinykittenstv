//
//  Event.swift
//  livestream
//
//  Created by Christopher Trott on 10/6/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation

// http://api.new.livestream.com/accounts/4175709/events
// http://api.new.livestream.com/accounts/4175709/events/4325133
public struct Event {
    let id : Int
    let shortName : String?
    let fullName : String?
    let description : String?
    let isLive : Bool?
    let imageUrl : NSURL?
    let streamUrl : NSURL?
}
