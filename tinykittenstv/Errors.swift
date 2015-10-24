//
//  Created by Christopher Trott on 10/22/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation

public enum EventError : ErrorType {
    case UnderlyingError(error: NSError)
    case InvalidResponse
    case ImageURLMissing
    case StreamURLMissing
    case UnknownError
    
    func localizedDescription() -> String {
        switch self {
        case .InvalidResponse:
            return "The server returned an invalid response.".l10()
        case .StreamURLMissing:
            return "The stream's URL could not be found.".l10()
        case .ImageURLMissing:
            return "The stream's image URL could not be found.".l10()
        case .UnderlyingError(let e):
            return e.localizedDescription
        default:
            return "An unknown error occurred. Please try again.".l10()
        }
    }
}