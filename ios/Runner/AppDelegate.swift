import Flutter
import StoreKit
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
      case "loadOccupation":
        result(UserDefaults.standard.string(forKey: "occupation"))
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

    let storeKitEntitlementsChannel = FlutterMethodChannel(
      name: "com.matsumotoboundary.constructioncalc/storekit_entitlements",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    storeKitEntitlementsChannel.setMethodCallHandler { call, result in
      guard #available(iOS 15.0, *) else {
        result(
          FlutterError(
            code: "STOREKIT2_UNAVAILABLE",
            message: "StoreKit 2 requires iOS 15 or later.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "loadVerifiedEntitlementProductIds":
        let arguments = call.arguments as? [String: Any]
        let synchronize = arguments?["synchronize"] as? Bool ?? false
        Task { @MainActor in
          do {
            if synchronize {
              try await AppStore.sync()
            }
            var productIds = Set<String>()
            for await entitlement in Transaction.currentEntitlements {
              guard case .verified(let transaction) = entitlement else {
                continue
              }
              productIds.insert(transaction.productID)
            }
            result(Array(productIds).sorted())
          } catch {
            result(
              FlutterError(
                code: "STOREKIT_ENTITLEMENTS_FAILED",
                message: "Verified StoreKit entitlements could not be loaded.",
                details: error.localizedDescription
              )
            )
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let restoreJournalChannel = FlutterMethodChannel(
      name: "jp.instant_estimate/backup_restore_journal",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    restoreJournalChannel.setMethodCallHandler { call, result in
      let fileManager = FileManager.default
      guard let applicationSupport = fileManager.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first else {
        result(FlutterError(code: "JOURNAL_PATH_FAILED", message: "Restore journal location is unavailable.", details: nil))
        return
      }
      let journalURL = applicationSupport.appendingPathComponent("backup_restore_journal.json")
      switch call.method {
      case "loadRestoreJournal":
        guard fileManager.fileExists(atPath: journalURL.path) else {
          result(nil)
          return
        }
        do {
          let data = try Data(contentsOf: journalURL)
          guard let journal = String(data: data, encoding: .utf8) else {
            result(FlutterError(code: "JOURNAL_READ_FAILED", message: "Restore journal is not valid UTF-8.", details: nil))
            return
          }
          result(journal)
        } catch {
          result(FlutterError(code: "JOURNAL_READ_FAILED", message: "Restore journal could not be read.", details: error.localizedDescription))
        }
      case "saveRestoreJournal":
        guard
          let arguments = call.arguments as? [String: Any],
          let journal = arguments["journal"] as? String
        else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Restore journal is required.", details: nil))
          return
        }
        do {
          try fileManager.createDirectory(
            at: applicationSupport,
            withIntermediateDirectories: true
          )
          try Data(journal.utf8).write(to: journalURL, options: .atomic)
          result(nil)
        } catch {
          result(FlutterError(code: "JOURNAL_WRITE_FAILED", message: "Restore journal could not be saved.", details: error.localizedDescription))
        }
      case "clearRestoreJournal":
        do {
          if fileManager.fileExists(atPath: journalURL.path) {
            try fileManager.removeItem(at: journalURL)
          }
          result(nil)
        } catch {
          result(FlutterError(code: "JOURNAL_CLEAR_FAILED", message: "Restore journal could not be cleared.", details: error.localizedDescription))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
