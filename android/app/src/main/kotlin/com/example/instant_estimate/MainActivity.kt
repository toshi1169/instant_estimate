package com.example.instant_estimate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "jp.instant_estimate/onboarding_preferences"
    private val historyChannelName = "jp.instant_estimate/calculator_history"
    private val settingsChannelName = "jp.instant_estimate/app_settings"
    private val estimateItemsChannelName = "jp.instant_estimate/estimate_items"
    private val productivityRecordsChannelName = "jp.instant_estimate/productivity_records"
    private val accessChannelName = "jp.instant_estimate/app_access"
    private val preferencesName = "instant_estimate_preferences"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
            when (call.method) {
                "hasSelectedLanguage" -> {
                    result.success(
                        preferences.contains("appLanguage") ||
                            preferences.contains("occupation"),
                    )
                }
                "saveLanguage" -> {
                    val language = call.argument<String>("language")
                    if (language == null) {
                        result.error("INVALID_ARGUMENT", "Language is required.", null)
                    } else {
                        preferences.edit().putString("appLanguage", language).apply()
                        result.success(null)
                    }
                }
                "hasSelectedOccupation" -> {
                    result.success(preferences.contains("occupation"))
                }
                "loadOccupation" -> {
                    result.success(preferences.getString("occupation", null))
                }
                "saveOccupation" -> {
                    val occupation = call.argument<String>("occupation")
                    if (occupation == null) {
                        result.error("INVALID_ARGUMENT", "Occupation is required.", null)
                    } else {
                        preferences.edit().putString("occupation", occupation).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            historyChannelName,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
            when (call.method) {
                "loadHistory" -> result.success(preferences.getString("calculatorHistory", null))
                "saveHistory" -> {
                    val history = call.argument<String>("history")
                    if (history == null) {
                        result.error("INVALID_ARGUMENT", "History is required.", null)
                    } else {
                        preferences.edit().putString("calculatorHistory", history).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            settingsChannelName,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
            when (call.method) {
                "loadSettings" -> result.success(
                    preferences.getString("appSettings", null),
                )
                "saveSettings" -> {
                    val settings = call.argument<String>("settings")
                    if (settings == null) {
                        result.error("INVALID_ARGUMENT", "Settings are required.", null)
                    } else {
                        preferences.edit().putString("appSettings", settings).apply()
                        result.success(null)
                    }
                }
                "loadThemeMode" -> result.success(
                    preferences.getString("themeMode", "system"),
                )
                "saveThemeMode" -> {
                    val themeMode = call.argument<String>("themeMode")
                    if (themeMode == null) {
                        result.error("INVALID_ARGUMENT", "Theme mode is required.", null)
                    } else {
                        preferences.edit().putString("themeMode", themeMode).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            estimateItemsChannelName,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
            when (call.method) {
                "loadEstimateItems" -> result.success(
                    preferences.getString("estimateItems", null),
                )
                "saveEstimateItems" -> {
                    val items = call.argument<String>("items")
                    if (items == null) {
                        result.error("INVALID_ARGUMENT", "Estimate items are required.", null)
                    } else {
                        preferences.edit().putString("estimateItems", items).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }


        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            productivityRecordsChannelName,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
            when (call.method) {
                "loadProductivityRecords" -> result.success(
                    preferences.getString("productivityRecords", null),
                )
                "saveProductivityRecords" -> {
                    val records = call.argument<String>("records")
                    if (records == null) {
                        result.error("INVALID_ARGUMENT", "Productivity records are required.", null)
                    } else {
                        preferences.edit().putString("productivityRecords", records).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }


        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            accessChannelName,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
            when (call.method) {
                "loadAccessState" -> result.success(
                    preferences.getString("appAccessState", null),
                )
                "saveAccessState" -> {
                    val accessState = call.argument<String>("accessState")
                    if (accessState == null) {
                        result.error("INVALID_ARGUMENT", "Access state is required.", null)
                    } else {
                        preferences.edit().putString("appAccessState", accessState).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
