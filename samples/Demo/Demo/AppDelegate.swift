import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  /// The key window.
  var window: UIWindow?
  /// Tells the delegate that the launch process is almost done and the app is almost ready to run.
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Override point for customization after application launch.
    return true
  }

}

