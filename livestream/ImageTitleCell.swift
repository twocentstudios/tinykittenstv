//
//  ImageTitleCell.swift
//  livestream
//
//  Created by Christopher Trott on 10/7/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit

class ImageTitleCell: UICollectionViewCell {
    private let imageView : UIImageView
    private let titleLabel : UILabel
    
    var viewModel : ImageTitleable? {
        didSet {
            if let imageData = viewModel?.imageData {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = nil
            }
            titleLabel.text = viewModel?.title
            self.setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.adjustsImageWhenAncestorFocused = true

        titleLabel = UILabel()
        titleLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Center
        titleLabel.font = UIFont.boldSystemFontOfSize(32)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        titleLabel.shadowOffset = CGSize(width: 0, height: -1)
        titleLabel.highlightedTextColor = UIColor.whiteColor().colorWithAlphaComponent(0.8)
        
        super.init(frame: frame)

        self.contentView.addSubview(imageView)
        self.contentView.addSubview(titleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let hBottomImageMargin : CGFloat = 16
        
        if (self.focused) {
            imageView.frame = self.contentView.bounds
            print("focused \(self.titleLabel.text)")
        } else {
            imageView.frame = CGRectInset(self.contentView.bounds, 0, 24)
        }
        titleLabel.frame = self.contentView.bounds
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: 0, y: CGRectGetMaxY(self.bounds) - CGRectGetHeight(titleLabel.frame) - hBottomImageMargin, width: CGRectGetWidth(self.contentView.bounds), height: CGRectGetHeight(titleLabel.frame))
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }) { () -> Void in }
    }
}
