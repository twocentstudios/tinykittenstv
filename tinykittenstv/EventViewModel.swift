//
//  Created by Christopher Trott on 10/22/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import AVFoundation

public class EventViewModel: Imageable, Titleable, Subtitleable, Descriptable, Playable {
    let title: String
    let subtitle: String
    let description: String
    let imageData: NSData?
    let streamUrl: NSURL?
    let isDetailLoaded: Bool
    lazy var player: AVPlayer? = {
        if let streamUrl = self.streamUrl {
            return AVPlayer(URL: streamUrl)
        } else {
            return nil
        }
    }()
    
    let model: Event
    
    init(model: Event, imageData: NSData?) {
        self.model = model
        
        self.title = model.fullName ?? "[No title]".l10()
        self.description = model.description ?? "[No description]".l10()
        self.imageData = imageData
        self.streamUrl = model.streamUrl
        self.isDetailLoaded = model.isDetailLoaded
        
        var subtitle = ""
        if let isLive = model.isLive {
            if !isLive {
                subtitle = "Offline"
            } else if let viewerCount = model.viewerCount {
                subtitle = "Live · \(viewerCount) viewers"
            } else {
                subtitle = "Live"
            }
        } else {
            subtitle = "Loading..."
        }
        self.subtitle = subtitle
    }
}

extension EventViewModel: Equatable {}
public func ==(lhs: EventViewModel, rhs: EventViewModel) -> Bool {
    return
        lhs.imageData == rhs.imageData &&
        lhs.streamUrl == rhs.streamUrl &&
        lhs.model == rhs.model;
}
