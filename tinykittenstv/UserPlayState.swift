//
//  UserPlayState.swift
//  tinykittenstv
//
//  Created by Christopher Trott on 4/13/17.
//  Copyright © 2017 twocentstudios. All rights reserved.
//

enum UserPlayState {
    case pause
    case play
    
    func toggle() -> UserPlayState {
        switch self {
        case .play: return .pause
        case .pause: return .play
        }
    }
}
