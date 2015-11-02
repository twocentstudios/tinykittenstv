//
//  Created by Christopher Trott on 10/22/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import AVFoundation

public struct EventViewModel: Imageable, Titleable, Descriptable, Playable {
    let title: String
    let description: String
    let imageData: NSData?
    let streamUrl: NSURL?
    
    let model : Event
    
    init(model: Event, imageData: NSData?) {
        self.model = model
        
        self.title = model.fullName ?? "[No title]".l10()
        self.description = model.description ?? "[No description]".l10()
        self.imageData = imageData
        self.streamUrl = model.streamUrl
    }
}

extension EventViewModel: Equatable {}
public func ==(lhs: EventViewModel, rhs: EventViewModel) -> Bool {
    
    return
        lhs.imageData == rhs.imageData &&
        lhs.streamUrl == rhs.streamUrl &&
        lhs.model == rhs.model;
}
