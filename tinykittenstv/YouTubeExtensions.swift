//
//  ReactiveExtensions.swift
//  tinykittenstv
//
//  Created by Christopher Trott on 4/1/17.
//  Copyright © 2017 twocentstudios. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import XCDYouTubeKit

extension XCDYouTubeClient {
    static let genericError = NSError(domain: "XCDYouTubeClient", code: 0, userInfo: nil)
    
    func rac_getVideoWithIdentifier(_ videoIdentifier: String) -> SignalProducer<XCDYouTubeVideo, NSError> {
        return SignalProducer({ (observer: Observer<XCDYouTubeVideo, NSError>, disposable: CompositeDisposable) in
            let operation = self.getVideoWithIdentifier(videoIdentifier, completionHandler: { (maybeVideo: XCDYouTubeVideo?, error: Error?) in
                if let error = error as? NSError {
                    observer.send(error: error)
                } else if let video = maybeVideo {
                    observer.send(value: video)
                    observer.sendCompleted()
                } else {
                    observer.send(error: XCDYouTubeClient.genericError)
                }
            })
            
            disposable.add {
                operation.cancel()
            }
        })
    }
}
