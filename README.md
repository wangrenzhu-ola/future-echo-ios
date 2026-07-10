# Future Echo

Future Echo is a native SwiftUI iPhone app that creates a neutral pause between a purchase impulse and a deliberate Wait, Skip, or Keep decision. Purchase context stays on-device.

## Requirements

- Xcode 26 or later
- Swift 5 language mode
- iOS 14.0 minimum deployment target

Generate the committed Xcode project after changing project membership:

```sh
ruby tools/create_project.rb
```

Build and test:

```sh
xcodebuild -project FutureEcho.xcodeproj -scheme FutureEcho -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
swift test
```

