//
//  Created by Christopher Trott on 10/7/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation

protocol ImageTitleable {
    var title : String { get }
    var imageData : NSData? { get }
}

extension ImageTitleable {
    func isLoaded() -> Bool {
        return imageData != nil
    }
}

