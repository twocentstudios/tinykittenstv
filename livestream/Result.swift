//
//  Result.swift
//  livestream
//
//  Created by Christopher Trott on 10/22/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

public struct Result<T, E> {
    let value : T?
    let error : E?
    
    init(value: T) {
        self.value = value
        self.error = nil
    }
    
    init(error: E) {
        self.error = error
        self.value = nil
    }
}