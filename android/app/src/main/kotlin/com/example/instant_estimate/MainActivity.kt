package com.example.instant_estimate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "jp.instant_estimate/onboarding_preferences"
    private val historyChannelName = "jp.instant_estimate/calculator_history"
    private val preferencesName = "instant_estimate_preferences"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(preferencesName, MODE_PRIVATE)
            when (call.method) {
                "hasSelectedOccupation" -> {
                    result.success(preferences.contains("occupation"))
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
    }
}
