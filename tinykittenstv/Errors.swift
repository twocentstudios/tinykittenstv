//
//  Created by Christopher Trott on 10/22/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Result

public enum EventError : Error {
    case underlyingError(error: NSError)
    case invalidResponse
    case imageURLMissing
    case streamURLMissing
    case unknownError
    
    func localizedDescription() -> String {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response.".l10()
        case .streamURLMissing:
            return "This stream is currently offline. Please try again later.".l10()
        case .imageURLMissing:
            return "The stream's image URL could not be found.".l10()
        case .underlyingError(let e):
            return e.localizedDescription
        default:
            return "An unknown error occurred. Please try again.".l10()
        }
    }
}

func toNSError(_ error: AnyError) -> NSError { return error as NSError }
