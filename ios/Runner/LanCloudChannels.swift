import Flutter
import UIKit
import UniformTypeIdentifiers
import SafariServices

/// iOS 原生通道实现。
///
/// 桌面 / Android 端这些能力都在各自的宿主里实现；iOS 之前是空白，
/// 导致「从其他应用上传」「拍照」「另存到文件」「分享」等一律失败。
/// 这里按 Dart 侧已有的调用契约（lib/core/*.dart 里的 MethodChannel）一一补齐。
final class LanCloudChannels: NSObject, FlutterPlugin {
  /// 通道 handler 不持有实例，用静态引用保证回调期间对象不被回收。
  private static var shared: LanCloudChannels?

  private enum Pending {
    case pickFiles
    case takePhoto
    case export
  }

  private var pendingResult: FlutterResult?
  private var pendingAction: Pending = .pickFiles

  static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let instance = LanCloudChannels()
    shared = instance

    FlutterMethodChannel(name: "lancloud/file_picker", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        instance.handleFilePicker(call, result)
      }
    FlutterMethodChannel(name: "lancloud/share", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        instance.handleShare(call, result)
      }
    FlutterMethodChannel(name: "lancloud/system", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        instance.handleSystem(call, result)
      }
    FlutterMethodChannel(name: "lancloud/external_link", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        instance.handleExternalLink(call, result)
      }
    FlutterMethodChannel(name: "lancloud/permissions", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        instance.handlePermissions(call, result)
      }
    FlutterMethodChannel(name: "lancloud/links", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        // iOS 的分享链接由 receive_sharing_intent 插件处理，这里保持空
        if call.method == "getInitialLink" {
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
  }

  // MARK: - 顶栏与容器

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
      ?? scenes.first as? UIWindowScene
    var controller = windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
      ?? windowScene?.windows.first?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  // MARK: - lancloud/file_picker

  private func handleFilePicker(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "pickFiles":
      presentDocumentPicker(result)
    case "takePhoto":
      presentCamera(result)
    case "saveFile":
      let args = call.arguments as? [String: Any] ?? [:]
      guard let path = args["path"] as? String, FileManager.default.fileExists(atPath: path) else {
        result(FlutterError(code: "not_found", message: "file not found", details: nil))
        return
      }
      let fileName = args["fileName"] as? String ?? (path as NSString).lastPathComponent
      exportFile(path: path, fileName: fileName, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 用系统「文件」选择器挑文件（对应 Android 的 ACTION_GET_CONTENT）。
  /// asCopy: true 会把选中的文件复制到应用沙盒，因此拿到的就是稳定本地路径。
  private func presentDocumentPicker(_ result: @escaping FlutterResult) {
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_host", message: "no view controller", details: nil))
      return
    }
    pendingResult = result
    pendingAction = .pickFiles
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [.item], asCopy: true
    )
    picker.allowsMultipleSelection = true
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  /// 调系统相机拍一张照片（对应 Android 的 ACTION_IMAGE_CAPTURE）。
  private func presentCamera(_ result: @escaping FlutterResult) {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      result(FlutterError(code: "no_camera", message: "no camera", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_host", message: "no view controller", details: nil))
      return
    }
    pendingResult = result
    pendingAction = .takePhoto
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  /// 用系统「文件」导出面板让用户自己选保存位置（对应 Android 的 CREATE_DOCUMENT）。
  private func exportFile(path: String, fileName: String, result: @escaping FlutterResult) {
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_host", message: "no view controller", details: nil))
      return
    }
    // 复制成用户期望的文件名，再交给导出面板
    let tmpDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("export_\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    let named = tmpDir.appendingPathComponent(fileName.isEmpty ? "file" : fileName)
    if let existing = try? Data(contentsOf: URL(fileURLWithPath: path)) {
      try? existing.write(to: named)
    }
    pendingResult = result
    pendingAction = .export
    let picker = UIDocumentPickerViewController(forExporting: [named], asCopy: true)
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  // MARK: - lancloud/share

  private func handleShare(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let subject = args["subject"] as? String ?? ""
    switch call.method {
    case "shareText":
      guard let text = args["text"] as? String, !text.isEmpty else {
        result(FlutterError(code: "bad_args", message: "text required", details: nil))
        return
      }
      presentActivity(items: [text], subject: subject, result: result)
    case "shareFile":
      guard let path = args["path"] as? String,
        FileManager.default.fileExists(atPath: path) else {
        result(FlutterError(code: "bad_args", message: "path required", details: nil))
        return
      }
      presentActivity(items: [URL(fileURLWithPath: path)], subject: subject, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentActivity(items: [Any], subject: String, result: @escaping FlutterResult) {
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_host", message: "no view controller", details: nil))
      return
    }
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    // iPad 上必须给 popover 锚点，否则崩
    if let popover = controller.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(
        x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    controller.completionWithItemsHandler = { _, _, _, _ in result(true) }
    presenter.present(controller, animated: true)
  }

  // MARK: - lancloud/system

  private func handleSystem(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "motionState":
      result([
        "reduceMotion": UIAccessibility.isReduceMotionEnabled,
        "touchExploration": UIAccessibility.isVoiceOverRunning,
      ])
    case "androidSdkInt":
      // 只有 Android 读这个；iOS 给安全默认值
      result(0)
    case "supportedAbis":
      result([String]())
    case "deviceInfo":
      let device = UIDevice.current
      let info = Bundle.main.infoDictionary
      result([
        "manufacturer": "Apple",
        "model": device.model,
        "release": device.systemVersion,
        "sdkInt": 0,
        "display": info?["CFBundleShortVersionString"] ?? "",
        "abis": ["arm64"],
        "versionCode": 0,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - lancloud/external_link

  private func handleExternalLink(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard call.method == "openCustomTab" else {
      result(FlutterMethodNotImplemented)
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    guard let raw = args["url"] as? String, let url = URL(string: raw) else {
      result(FlutterError(code: "bad_args", message: "url required", details: nil))
      return
    }
    let scheme = url.scheme?.lowercased()
    if scheme != "http" && scheme != "https" {
      // 非 http(s)：交给系统打开（比如跳设置页）
      UIApplication.shared.open(url, options: [:]) { ok in result(ok) }
      return
    }
    guard let presenter = topViewController() else {
      result(false)
      return
    }
    // 应用内 Safari 呈现，等同 Android 的 Custom Tabs
    let safari = SFSafariViewController(url: url)
    presenter.present(safari, animated: true)
    result(true)
  }

  // MARK: - lancloud/permissions

  private func handlePermissions(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "status":
      // iOS 没有「安装未知应用」「忽略电池优化」这两项概念
      result(["install": "unknown", "battery": "unknown"])
    case "openAppSettings":
      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { ok in result(ok) }
    case "openInstallSettings", "requestBattery", "openDefaultLinksSettings":
      result(false)
    case "requestLocalNetwork":
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - 选择器回调

extension LanCloudChannels: UIDocumentPickerDelegate {
  func documentPicker(
    _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
  ) {
    let result = pendingResult
    let action = pendingAction
    pendingResult = nil
    guard let result else { return }
    switch action {
    case .pickFiles:
      // 选择：asCopy 已把文件复制进沙盒，直接返回路径列表
      result(urls.map { $0.path })
    default:
      // 导出：返回实际落地的文件名
      result(urls.first?.lastPathComponent)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pendingResult
    pendingResult = nil
    result?(nil)
  }
}

extension LanCloudChannels: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    let result = pendingResult
    pendingResult = nil
    picker.dismiss(animated: true)
    guard let image = info[.originalImage] as? UIImage,
      let data = image.jpegData(compressionQuality: 0.9)
    else {
      result?(nil)
      return
    }
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
      "photo", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let file = dir.appendingPathComponent("qr_\(Int(Date().timeIntervalSince1970)).jpg")
    do {
      try data.write(to: file)
      result?([file.path])
    } catch {
      result?(FlutterError(code: "photo_failed", message: error.localizedDescription, details: nil))
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    let result = pendingResult
    pendingResult = nil
    picker.dismiss(animated: true)
    result?(nil)
  }
}
