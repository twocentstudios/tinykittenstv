//
//  Created by Christopher Trott on 11/2/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit

class ImageTitleDescriptionCell: UITableViewCell {

    private let playButtonTapGesture: UITapGestureRecognizer
    internal var playButtonTapGestureBlock: ( () -> Void )?

    var viewModel: protocol<Imageable, Titleable, Subtitleable>? {
        didSet {
            textLabel?.text = viewModel?.title
            if let imageData = viewModel?.imageData {
                imageView?.image = UIImage(data: imageData)
            } else {
                imageView?.image = nil
            }
            detailTextLabel?.text = viewModel?.subtitle
            self.setNeedsLayout()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.playButtonTapGesture = UITapGestureRecognizer()

        super.init(style: .Subtitle, reuseIdentifier: NSStringFromClass(ImageTitleDescriptionCell.self))
        
        self.playButtonTapGesture.addTarget(self, action: "didTapPlayButton:")
        self.playButtonTapGesture.allowedPressTypes = [NSNumber(integer: UIPressType.PlayPause.rawValue)];
        self.addGestureRecognizer(playButtonTapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didTapPlayButton(sender: AnyObject) {
        guard let gesture = sender as? UIGestureRecognizer else { return }
        if gesture.state != UIGestureRecognizerState.Recognized { return }
        if let playButtonTapGestureBlock = playButtonTapGestureBlock {
            playButtonTapGestureBlock()
        }
    }
}
