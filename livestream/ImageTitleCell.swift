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
    private let shadowView : UIImageView
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
        imageView.layer.cornerRadius = 4.0
        
        shadowView = UIImageView(image: UIImage(named: "placeholder-image")?.imageWithRenderingMode(.AlwaysTemplate))
        shadowView.contentMode = .ScaleAspectFit
        shadowView.tintColor = UIColor.grayColor().colorWithAlphaComponent(0.8)
        shadowView.backgroundColor = UIColor.whiteColor()
        shadowView.clipsToBounds = false
        shadowView.layer.shadowColor = UIColor.blackColor().CGColor
        
        titleLabel = UILabel()
        titleLabel.numberOfLines = 3
        titleLabel.textAlignment = .Center
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        titleLabel.shadowOffset = CGSize(width: 0.0, height: 1.0)
        titleLabel.highlightedTextColor = UIColor.whiteColor().colorWithAlphaComponent(0.8)
        
        super.init(frame: frame)

        self.contentView.addSubview(shadowView)
        self.contentView.addSubview(imageView)
        self.contentView.addSubview(titleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let viewWidth = CGRectGetWidth(self.contentView.bounds)
        let viewHeight = CGRectGetHeight(self.contentView.bounds)
        let vBottomImageMargin : CGFloat = 100.0
        let hMargin : CGFloat = 3.0
        let vMargin : CGFloat = 4.0
        let hUnfocusedMargin : CGFloat = 14.0
        let vFocusedTopMargin : CGFloat = 40.0
        
        titleLabel.frame = CGRect(x: 0.0, y: 0.0, width: viewWidth - hMargin * 2.0, height: 0.0)
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: hMargin, y: viewHeight - vBottomImageMargin, width: viewWidth - hMargin * 2.0, height: CGRectGetHeight(titleLabel.frame))
        
        if (self.focused) {
            imageView.frame = CGRect(x: hMargin, y: vFocusedTopMargin, width: viewWidth - hMargin * 2.0, height: viewHeight - vBottomImageMargin - vMargin - vFocusedTopMargin)
            titleLabel.alpha = 1.0;
            shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 100.0)
            shadowView.layer.shadowRadius = 50.0
            shadowView.layer.shadowOpacity = 0.5
        } else {
            imageView.frame = CGRect(x: hUnfocusedMargin, y: vBottomImageMargin + vMargin, width: viewWidth - hUnfocusedMargin * 2, height: viewHeight - vBottomImageMargin * 2 - vMargin * 2)
            titleLabel.alpha = 0.0;
            shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 8.0)
            shadowView.layer.shadowRadius = 4.0
            shadowView.layer.shadowOpacity = 0.2
        }

        shadowView.frame = imageView.frame
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }) { () -> Void in }
    }
}
