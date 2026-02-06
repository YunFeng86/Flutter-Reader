import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let shareChannel = FlutterMethodChannel(
        name: "flutter_reader/ios_share",
        binaryMessenger: controller.binaryMessenger
      )
      shareChannel.setMethodCallHandler { call, result in
        guard call.method == "shareFile" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "Missing required argument: path",
              details: nil
            )
          )
          return
        }

        let url = URL(fileURLWithPath: path)
        DispatchQueue.main.async {
          let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
          // iPad 上必须指定 popover 锚点，否则会崩溃。
          if let popover = activity.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(
              x: controller.view.bounds.midX,
              y: controller.view.bounds.midY,
              width: 0,
              height: 0
            )
            popover.permittedArrowDirections = []
          }
          controller.present(activity, animated: true, completion: nil)
          result(nil)
        }
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
