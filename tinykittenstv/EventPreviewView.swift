//
//  Created by Christopher Trott on 11/2/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit
import AVFoundation

class EventPreviewView: UIView {
    let playerLayer: AVPlayerLayer
    let imageView: UIImageView
    let descriptionLabel: UILabel
    
    var viewModel: protocol<Imageable, Descriptable, Playable>? {
        didSet {
            if let imageData = viewModel?.imageData {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = UIImage(named: "placeholder-image")
            }
            descriptionLabel.text = viewModel?.description
            if let streamUrl = viewModel?.streamUrl {
                playerLayer.hidden = false
                imageView.hidden = true
                if streamUrl != oldValue?.streamUrl {
                    let player = AVPlayer(URL: streamUrl)
                    playerLayer.player = player
                    player.play()
                }
            } else {
                playerLayer.player?.pause()
                playerLayer.player = nil
                playerLayer.hidden = true
                imageView.hidden = false
            }
            self.setNeedsLayout()
        }
    }
    
    internal override init(frame: CGRect) {
        self.imageView = UIImageView()
        self.imageView.contentMode = .ScaleAspectFit
        self.imageView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        self.imageView.layer.cornerRadius = 10.0
        self.imageView.clipsToBounds = true
        
        self.playerLayer = AVPlayerLayer()
        self.playerLayer.cornerRadius = 10.0
        self.playerLayer.masksToBounds = true
        self.playerLayer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3).CGColor
        self.playerLayer.hidden = true
        
        self.descriptionLabel = UILabel()
        self.descriptionLabel.numberOfLines = 0
        self.descriptionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        
        super.init(frame: frame)

        self.addSubview(self.imageView)
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
        
        self.imageView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: vImageHeight)
        self.playerLayer.frame = CGRect(x: 0, y: 0, width: viewWidth, height: vImageHeight)
        self.descriptionLabel.frame = CGRect(x: 0, y: vImageHeight + vInterImageDescriptionMargin, width: viewWidth, height: vDescriptionHeight)
        
    }
    
    override func canBecomeFocused() -> Bool {
        return false
    }
}
