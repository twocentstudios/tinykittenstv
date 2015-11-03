# TinyKittens TV

TinyKittens TV is a tvOS app for watching the TinyKittens Livestream events on your Apple TV.

See [tinykittens.com](http://tinykittens.com) for more info about the TinyKittens non-profit society.

## Links

* [App Store](https://itunes.apple.com/us/app/tinykittens-rescue-kitten-tv/id1052349833?ls=1&mt=8) (it's free).
* [Blog post](http://twocentstudios.com/2015/10/29/fall-2015-project-wrap-up/#tinykittens-tv) about the project.

![Screenshot 1](https://github.com/twocentstudios/tinykittenstv/blob/master/marketing/tinykittens-tv-home.png)
![Screenshot 2](https://github.com/twocentstudios/tinykittenstv/blob/master/marketing/tinykittens-tv-event.png)

## Getting started

1. Clone the repo. `$ git clone git://github.com/twocentstudios/tinykittenstv.git`.
1. Install the gems. `$ bundle install` (n.b. `cocoapods-expert-difficulty` may not be necessary after the tvOS beta period).
1. Install the pods. `$ pod install`.
1. Open `tinykittenstv.xcworkspace`.
1. Build!
1. Optional: Change `accountId` in `AppDelegate.swift` to the account id of your favorite Livestream account.

## Technologies

TinyKittens TV was written during the tvOS beta period. It is written in Swift, uses CocoaPods, and has the Gloss JSON library as a dependency.

On a personal note, it was my first Swift app of consequence (I did a few experiments with protocols, view models, and using my own simple Result type). I intentionally used very few dependencies to get a feel for Swift on its own. I wanted to learn about the focus system and the general modifications made to UIKit for tvOS.

## License

MIT License for source.

All rights are reserved for image assets.

## About

TinyKittens TV was created by [Christopher Trott](http://twitter.com/twocentstudios). My development shop is called [twocentstudios](http://twocentstudios.com).

Images assets were adapted from tinykittens.com created by Shelly Roche.

Thanks to Shelly Roche for her work at the TinyKittens non-profit. Without so this project would not exist.
