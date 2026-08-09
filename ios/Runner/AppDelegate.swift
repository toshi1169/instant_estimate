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
      case "hasSelectedLanguage":
        // 既存利用者は業種選択済みなら、更新後も日本語でそのまま起動する。
        result(
          UserDefaults.standard.object(forKey: "appLanguage") != nil
            || UserDefaults.standard.object(forKey: "occupation") != nil
        )
      case "saveLanguage":
        guard
          let arguments = call.arguments as? [String: Any],
          let language = arguments["language"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "Language is required.",
              details: nil
            )
          )
          return
        }
        UserDefaults.standard.set(language, forKey: "appLanguage")
        result(nil)
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
      case "loadSettings":
        result(UserDefaults.standard.string(forKey: "appSettings"))
      case "saveSettings":
        guard
          let arguments = call.arguments as? [String: Any],
          let settings = arguments["settings"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "Settings are required.",
              details: nil
            )
          )
          return
        }
        UserDefaults.standard.set(settings, forKey: "appSettings")
        result(nil)
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

    let estimateItemsChannel = FlutterMethodChannel(
      name: "jp.instant_estimate/estimate_items",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    estimateItemsChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "loadEstimateItems":
        result(UserDefaults.standard.string(forKey: "estimateItems"))
      case "saveEstimateItems":
        guard
          let arguments = call.arguments as? [String: Any],
          let items = arguments["items"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "Estimate items are required.",
              details: nil
            )
          )
          return
        }
        UserDefaults.standard.set(items, forKey: "estimateItems")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let productivityRecordsChannel = FlutterMethodChannel(
      name: "jp.instant_estimate/productivity_records",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    productivityRecordsChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "loadProductivityRecords":
        result(UserDefaults.standard.string(forKey: "productivityRecords"))
      case "saveProductivityRecords":
        guard
          let arguments = call.arguments as? [String: Any],
          let records = arguments["records"] as? String
        else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Productivity records are required.", details: nil))
          return
        }
        UserDefaults.standard.set(records, forKey: "productivityRecords")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let accessChannel = FlutterMethodChannel(
      name: "jp.instant_estimate/app_access",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    accessChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "loadAccessState":
        result(UserDefaults.standard.string(forKey: "appAccessState"))
      case "saveAccessState":
        guard
          let arguments = call.arguments as? [String: Any],
          let accessState = arguments["accessState"] as? String
        else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Access state is required.", details: nil))
          return
        }
        UserDefaults.standard.set(accessState, forKey: "appAccessState")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
