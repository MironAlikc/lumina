import Flutter
import UIKit
import Vision

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

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OcrPlugin") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "lumina/ocr",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      OcrPlugin.handle(call, result: result)
    }
  }
}

enum OcrPlugin {
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognize" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let rawPath = args["path"] as? String,
      let image = image(from: rawPath),
      let cgImage = image.cgImage
    else {
      result("")
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let text = recognize(cgImage: cgImage)
      DispatchQueue.main.async {
        result(text)
      }
    }
  }

  private static func image(from path: String) -> UIImage? {
    let cleaned = path.replacingOccurrences(of: "file://", with: "")
    if let image = UIImage(contentsOfFile: cleaned) {
      return image
    }
    if let url = URL(string: path) {
      return UIImage(contentsOfFile: url.path)
    }
    return nil
  }

  private static func recognize(cgImage: CGImage) -> String {
    if let text = run(cgImage: cgImage, languages: ["uk-UA", "ru-RU", "en-US"]),
       !text.isEmpty {
      return text
    }
    return run(cgImage: cgImage, languages: nil) ?? ""
  }

  private static func run(cgImage: CGImage, languages: [String]?) -> String? {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.minimumTextHeight = 0.012
    if let languages {
      request.recognitionLanguages = languages
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
      return (request.results ?? [])
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")
    } catch {
      return nil
    }
  }
}