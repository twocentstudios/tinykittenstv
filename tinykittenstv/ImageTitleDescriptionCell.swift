//
//  Created by Christopher Trott on 11/2/15.
//  Copyright © 2015 twocentstudios. All rights reserved.
//

import UIKit

class ImageTitleDescriptionCell: UITableViewCell {

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
        super.init(style: .Subtitle, reuseIdentifier: NSStringFromClass(ImageTitleDescriptionCell.self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
