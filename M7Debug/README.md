# M7 Debug
**M7 Debug** shows motion information as reported by the motion coprocessor in the A7 chip. Requires iPhone 5S and iOS 7.

M7 Debug shows the current activity (stationary, walking, running, or automotive); the M7’s confidence, when the activity started, and the number of steps the user has taken since the app was launched. This is taken directly from Core Motion, so [see its documentation][1] for more information.

This app won’t show anything useful when running in the simulator because the simulator doesn't support motion activities or step counting. Since I don’t subscribe to the iOS Developer Program, this means that M7 Debug has never actually been tested on an iPhone 5S. Whoops.

[1]: https://developer.apple.com/library/ios/documentation/CoreMotion/Reference/CoreMotion_Reference/_index.html