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
                    player.muted = true
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
        
        self.layer.cornerRadius = 10.0
        self.clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let viewWidth: CGFloat = CGRectGetWidth(self.bounds)
        let viewHeight: CGFloat = CGRectGetHeight(self.bounds)
        
        let vMargin: CGFloat = 10.0
        let hMargin: CGFloat = 20.0
        
        let vImageHeight: CGFloat = viewWidth * (9.0/16.0)
        let vInterImageDescriptionMargin: CGFloat = 14.0
        let vDescriptionHeight: CGFloat = viewHeight - vImageHeight - vInterImageDescriptionMargin
        let hDescriptionWidth: CGFloat = viewWidth - hMargin * 2
        
        self.playerLayer.frame = CGRect(x: 0, y: 0, width: viewWidth, height: vImageHeight)
        if self.focused {
            self.playerLayer.opacity = 0.0
            self.backgroundColor = UIColor.whiteColor()
            self.descriptionLabel.frame = CGRect(x: hMargin, y: vMargin, width: hDescriptionWidth, height: viewHeight - vMargin * 2)
            self.descriptionLabel.sizeToFit()
            self.statusLabel.hidden = true
        } else {
            self.playerLayer.opacity = 1.0
            self.backgroundColor = UIColor.clearColor()
            let descriptionFitHeight = self.descriptionLabel.sizeThatFits(CGSize(width: hDescriptionWidth, height: 0)).height
            self.descriptionLabel.frame = CGRect(x: hMargin, y: vImageHeight + vInterImageDescriptionMargin, width: hDescriptionWidth, height: min(vDescriptionHeight, descriptionFitHeight))
            self.statusLabel.hidden = false
        }
        self.statusLabel.sizeToFit()
        self.statusLabel.center = CGPoint(x: CGRectGetMidX(self.playerLayer.frame), y: CGRectGetMidY(self.playerLayer.frame))
        
    }
    
    override func canBecomeFocused() -> Bool {
        return true
    }
    
    override func shouldUpdateFocusInContext(context: UIFocusUpdateContext) -> Bool {
        return true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }) { }
    }

}
