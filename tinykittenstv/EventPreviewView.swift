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
    
    var viewModel: (Descriptable & Playable & Subtitleable)? {
        didSet {
            descriptionLabel.text = viewModel?.description
            statusLabel.text = viewModel?.subtitle
            if let player = viewModel?.player {
                playerLayer.player = player
                player.isMuted = true
                player.play()
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
        self.playerLayer.backgroundColor = UIColor.black.withAlphaComponent(0.3).cgColor

        self.statusLabel = UILabel()
        self.statusLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title3)
        self.statusLabel.numberOfLines = 1
        self.statusLabel.textAlignment = .center
        self.statusLabel.textColor = UIColor.black.withAlphaComponent(0.5)
        self.statusLabel.shadowColor = UIColor.white.withAlphaComponent(1)
        self.statusLabel.shadowOffset = CGSize(width: 0, height: -1)
        
        self.descriptionLabel = UILabel()
        self.descriptionLabel.numberOfLines = 0
        self.descriptionLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        
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
        
        let viewWidth: CGFloat = self.bounds.width
        let viewHeight: CGFloat = self.bounds.height
        
        let vMargin: CGFloat = 10.0
        let hMargin: CGFloat = 20.0
        
        let vImageHeight: CGFloat = viewWidth * (9.0/16.0)
        let vInterImageDescriptionMargin: CGFloat = 14.0
        let vDescriptionHeight: CGFloat = viewHeight - vImageHeight - vInterImageDescriptionMargin
        let hDescriptionWidth: CGFloat = viewWidth - hMargin * 2
        
        self.playerLayer.frame = CGRect(x: 0, y: 0, width: viewWidth, height: vImageHeight)
        if self.isFocused {
            self.playerLayer.opacity = 0.0
            self.backgroundColor = UIColor.white
            self.descriptionLabel.frame = CGRect(x: hMargin, y: vMargin, width: hDescriptionWidth, height: viewHeight - vMargin * 2)
            self.descriptionLabel.sizeToFit()
            self.statusLabel.isHidden = true
        } else {
            self.playerLayer.opacity = 1.0
            self.backgroundColor = UIColor.clear
            let descriptionFitHeight = self.descriptionLabel.sizeThatFits(CGSize(width: hDescriptionWidth, height: 0)).height
            self.descriptionLabel.frame = CGRect(x: hMargin, y: vImageHeight + vInterImageDescriptionMargin, width: hDescriptionWidth, height: min(vDescriptionHeight, descriptionFitHeight))
            self.statusLabel.isHidden = false
        }
        self.statusLabel.sizeToFit()
        self.statusLabel.center = CGPoint(x: self.playerLayer.frame.midX, y: self.playerLayer.frame.midY)
        
    }
    
    override var canBecomeFocused : Bool {
        return true
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }) { }
    }

}
