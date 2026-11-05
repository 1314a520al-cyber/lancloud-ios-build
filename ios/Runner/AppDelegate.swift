import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // iOS 原生通道（选择文件 / 拍照 / 另存 / 分享 / 系统信息 / 外链）
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LanCloudChannels") {
      LanCloudChannels.register(with: registrar)
    }
  }
}
