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

        titleLabel = UILabel()
        titleLabel.textAlignment = .Center
        
        super.init(frame: frame)

        self.addSubview(imageView)
        self.addSubview(titleLabel)
        
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = UIColor.redColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let hBottomImageMargin : CGFloat = 10
        
        imageView.frame = self.contentView.bounds
        
        titleLabel.frame = self.contentView.bounds
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: 0, y: CGRectGetMaxY(self.bounds) - CGRectGetHeight(titleLabel.frame) - hBottomImageMargin, width: CGRectGetWidth(self.contentView.bounds), height: CGRectGetHeight(titleLabel.frame))
    }
}
