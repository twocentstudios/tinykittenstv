//
//  Created by Christopher Trott on 10/22/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import Foundation

extension String {
    func l10() -> String {
        return String.localizedStringWithFormat(self)
    }
}


protocol Identifiable {
    func =~=(lhs: Self, rhs: Self) -> Bool
}

infix operator =~= { associativity none precedence 130 }

func =~=<T : Identifiable>(lhs: [T], rhs: [T]) -> Bool {
    if lhs.count != rhs.count { return false }
    
    let zipped = zip(lhs, rhs)
    let mapped = zipped.map { (lElement, rElement) -> Bool in
        return lElement =~= rElement
    }
    let reduced = mapped.reduce(true) { (element, result) -> Bool in
        return element && result
    }
    return reduced
}
