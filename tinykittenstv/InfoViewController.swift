//
//  InfoViewController.swift
//  tinykittenstv
//
//  Created by Christopher Trott on 4/13/17.
//  Copyright © 2017 twocentstudios. All rights reserved.
//

import UIKit
import Mortar

final class InfoViewController: UIViewController {
    enum ViewData {
        case normal(String)
        case error(String)
    }
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title2)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    let viewData: ViewData
    
    init(_ viewData: ViewData) {
        self.viewData = viewData
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view |+| [ infoLabel ]
        infoLabel |=| view.m_edges ~ (80, 80, 80, 80)
        
        switch viewData {
        case .normal(let text):
            infoLabel.text = text
            infoLabel.textColor = UIColor.black
        case .error(let text):
            infoLabel.text = text
            infoLabel.textColor = UIColor.red
        }
    }
}
