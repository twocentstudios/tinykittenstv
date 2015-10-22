//
//  ImageTitleViewModel.swift
//  livestream
//
//  Created by Christopher Trott on 10/7/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit

protocol ImageTitleable {
    var title : String { get }
    var imageData : NSData? { get }
}

public struct EventViewModel : ImageTitleable {
    let title : String
    let imageData : NSData?
    
    let model : Event
    
    func isLoaded() -> Bool {
        return imageData != nil
    }
}
