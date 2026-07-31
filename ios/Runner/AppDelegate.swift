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

    let channel = FlutterMethodChannel(
      name: "jp.instant_estimate/onboarding_preferences",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "hasSelectedOccupation":
        result(UserDefaults.standard.object(forKey: "occupation") != nil)
      case "saveOccupation":
        guard
          let arguments = call.arguments as? [String: Any],
          let occupation = arguments["occupation"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "Occupation is required.",
              details: nil
            )
          )
          return
        }
        UserDefaults.standard.set(occupation, forKey: "occupation")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let historyChannel = FlutterMethodChannel(
      name: "jp.instant_estimate/calculator_history",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    historyChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "loadHistory":
        result(UserDefaults.standard.string(forKey: "calculatorHistory"))
      case "saveHistory":
        guard
          let arguments = call.arguments as? [String: Any],
          let history = arguments["history"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "History is required.",
              details: nil
            )
          )
          return
        }
        UserDefaults.standard.set(history, forKey: "calculatorHistory")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let settingsChannel = FlutterMethodChannel(
      name: "jp.instant_estimate/app_settings",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    settingsChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "loadThemeMode":
        result(UserDefaults.standard.string(forKey: "themeMode") ?? "system")
      case "saveThemeMode":
        guard
          let arguments = call.arguments as? [String: Any],
          let themeMode = arguments["themeMode"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "Theme mode is required.",
              details: nil
            )
          )
          return
        }
        UserDefaults.standard.set(themeMode, forKey: "themeMode")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
