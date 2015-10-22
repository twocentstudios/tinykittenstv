//
//  EventViewModel.swift
//  livestream
//
//  Created by Christopher Trott on 10/22/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation

public struct EventViewModel : ImageTitleable {
    let title : String
    let imageData : NSData?
    
    let model : Event
    
    init(model: Event, imageData : NSData?) {
        self.model = model
        
        self.title = model.fullName ?? "[No title]".l10()
        self.imageData = imageData
    }
}
