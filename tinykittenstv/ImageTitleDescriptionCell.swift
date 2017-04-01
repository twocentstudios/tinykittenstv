//
//  Created by Christopher Trott on 11/2/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit

class ImageTitleDescriptionCell: UITableViewCell {

    fileprivate let playButtonTapGesture: UITapGestureRecognizer
    internal var playButtonTapGestureBlock: ( () -> Void )?

    var viewModel: (Imageable & Titleable & Subtitleable)? {
        didSet {
            textLabel?.text = viewModel?.title
            if let imageData = viewModel?.imageData {
                imageView?.image = UIImage(data: imageData as Data)
            } else {
                imageView?.image = nil
            }
            detailTextLabel?.text = viewModel?.subtitle
            self.setNeedsLayout()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.playButtonTapGesture = UITapGestureRecognizer()

        super.init(style: .subtitle, reuseIdentifier: NSStringFromClass(ImageTitleDescriptionCell.self))
        
        self.playButtonTapGesture.addTarget(self, action: #selector(ImageTitleDescriptionCell.didTapPlayButton(_:)))
        self.playButtonTapGesture.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue as Int)];
        self.addGestureRecognizer(playButtonTapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didTapPlayButton(_ sender: AnyObject) {
        guard let gesture = sender as? UIGestureRecognizer else { return }
        if gesture.state != UIGestureRecognizerState.recognized { return }
        if let playButtonTapGestureBlock = playButtonTapGestureBlock {
            playButtonTapGestureBlock()
        }
    }
}
