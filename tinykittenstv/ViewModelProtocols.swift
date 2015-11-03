//
//  Created by Christopher Trott on 10/7/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import AVFoundation

protocol Titleable {
    var title: String { get }
}

protocol Subtitleable {
    var subtitle: String { get }
}

protocol Descriptable {
    var description: String { get }
}

protocol Imageable {
    var imageData: NSData? { get }
}

protocol Playable {
    var streamUrl: NSURL? { get }
}

extension Imageable {
    func isLoaded() -> Bool {
        return imageData != nil
    }
}

extension Playable {
    func isLoaded() -> Bool {
        return streamUrl != nil
    }
}

