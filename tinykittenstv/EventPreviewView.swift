//
//  Created by Christopher Trott on 11/2/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit
import AVFoundation

class EventPreviewView: UIView {
    let playerLayer: AVPlayerLayer
    let statusLabel: UILabel
    let descriptionLabel: UILabel
    
    var viewModel: protocol<Descriptable, Playable, Subtitleable>? {
        didSet {
            descriptionLabel.text = viewModel?.description
            statusLabel.text = viewModel?.subtitle
            if let streamUrl = viewModel?.streamUrl {
                if streamUrl != oldValue?.streamUrl {
                    let player = AVPlayer(URL: streamUrl)
                    playerLayer.player = player
                    player.play()
                }
            } else {
                playerLayer.player?.pause()
                playerLayer.player = nil
            }
            self.setNeedsLayout()
        }
    }
    
    internal override init(frame: CGRect) {
        self.playerLayer = AVPlayerLayer()
        self.playerLayer.cornerRadius = 10.0
        self.playerLayer.masksToBounds = true
        self.playerLayer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3).CGColor

        self.statusLabel = UILabel()
        self.statusLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle3)
        self.statusLabel.numberOfLines = 1
        self.statusLabel.textAlignment = .Center
        self.statusLabel.textColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        self.statusLabel.shadowColor = UIColor.whiteColor().colorWithAlphaComponent(1)
        self.statusLabel.shadowOffset = CGSize(width: 0, height: -1)
        
        self.descriptionLabel = UILabel()
        self.descriptionLabel.numberOfLines = 0
        self.descriptionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        
        super.init(frame: frame)

        self.addSubview(self.statusLabel)
        self.layer.addSublayer(self.playerLayer)
        self.addSubview(self.descriptionLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let viewWidth: CGFloat = CGRectGetWidth(self.bounds)
        let viewHeight: CGFloat = CGRectGetHeight(self.bounds)
        
        let vImageHeight: CGFloat = viewWidth * (9.0/16.0)
        let vInterImageDescriptionMargin: CGFloat = 6.0
        let vDescriptionHeight: CGFloat = viewHeight - vImageHeight - vInterImageDescriptionMargin
        
        self.playerLayer.frame = CGRect(x: 0, y: 0, width: viewWidth, height: vImageHeight)
        self.descriptionLabel.frame = CGRect(x: 0, y: vImageHeight + vInterImageDescriptionMargin, width: viewWidth, height: vDescriptionHeight)
        self.statusLabel.sizeToFit()
        self.statusLabel.center = CGPoint(x: CGRectGetMidX(self.playerLayer.frame), y: CGRectGetMidY(self.playerLayer.frame))
        
    }
    
    override func canBecomeFocused() -> Bool {
        return false
    }
}
