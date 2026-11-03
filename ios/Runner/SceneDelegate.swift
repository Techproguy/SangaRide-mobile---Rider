import Flutter
import UIKit

final class SensitiveScreenGuard {
  static let shared = SensitiveScreenGuard()
  static let channelName = "com.sangatechnologies.ride/sensitive_screen"

  private var isProtected = false
  private var covers: [UIView] = []

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setProtected" else { return result(FlutterMethodNotImplemented) }
      self?.isProtected = call.arguments as? Bool ?? false
      if self?.isProtected == false { self?.removeCovers() }
      result(nil)
    }
  }

  func coverIfProtected(in scene: UIScene) {
    guard isProtected, covers.isEmpty, let windowScene = scene as? UIWindowScene else { return }
    for window in windowScene.windows {
      let cover = UIView(frame: window.bounds)
      cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      cover.backgroundColor = launchBackground
      window.addSubview(cover)
      covers.append(cover)
    }
  }

  func removeCovers() {
    covers.forEach { $0.removeFromSuperview() }
    covers.removeAll()
  }

  private var launchBackground: UIColor {
    let launch = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
    return launch?.view.backgroundColor ?? .white
  }
}

class SceneDelegate: FlutterSceneDelegate {
  override func sceneWillResignActive(_ scene: UIScene) {
    SensitiveScreenGuard.shared.coverIfProtected(in: scene)
    super.sceneWillResignActive(scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    SensitiveScreenGuard.shared.removeCovers()
    super.sceneDidBecomeActive(scene)
  }
}
