//
//  VideoDescriptionView.swift
//  tinykittenstv
//
//  Created by Christopher Trott on 4/13/17.
//  Copyright © 2017 twocentstudios. All rights reserved.
//

import Mortar
import UIKit

struct VideoDescriptionViewData {
    let title: String
    let description: String
}

final class VideoDescriptionView: UIView {
    
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    
    var viewData: VideoDescriptionViewData? {
        didSet {
            titleLabel.text = viewData?.title
            descriptionLabel.text = viewData?.description
            self.setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title2)
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title3)
        
        titleLabel.textAlignment = .center
        descriptionLabel.textAlignment = .center
        
        titleLabel.numberOfLines = 0
        descriptionLabel.numberOfLines = 0
        
        titleLabel.textColor = Color.white
        descriptionLabel.textColor = Color.white
        
        let view = self
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        
        view |+| [
            blurView
        ]
        
        blurView.contentView |+| [
            titleLabel,
            descriptionLabel
        ]
        
        let vMargin = 60
        let hMargin = 40
        
        blurView |=| view
        titleLabel.m_top |=| view.m_top + vMargin
        descriptionLabel.m_top |=| titleLabel.m_bottom + vMargin
        descriptionLabel.m_bottom |=| view.m_bottom - vMargin ! .low
        [titleLabel.m_leading, titleLabel.m_trailing] |=| [view.m_leading + hMargin, view.m_trailing - hMargin]
        [descriptionLabel.m_leading, descriptionLabel.m_trailing] |=| [view.m_leading + hMargin, view.m_trailing - hMargin]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
