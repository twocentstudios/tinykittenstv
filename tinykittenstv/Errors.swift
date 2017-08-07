//
//  Created by Christopher Trott on 10/22/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation
import Result

func toNSError(_ error: AnyError) -> NSError { return error as NSError }
