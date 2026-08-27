package com.example.instant_estimate

import android.util.AtomicFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "jp.instant_estimate/onboarding_preferences"
    private val historyChannelName = "jp.instant_estimate/calculator_history"
    private val settingsChannelName = "jp.instant_estimate/app_settings"
    private val estimateItemsChannelName = "jp.instant_estimate/estimate_items"
    private val productivityRecordsChannelName = "jp.instant_estimate/productivity_records"
    private val accessChannelName = "jp.instant_estimate/app_access"
    private val restoreJournalChannelName = "jp.instant_estimate/backup_restore_journal"
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            restoreJournalChannelName,
        ).setMethodCallHandler { call, result ->
            val journalFile = AtomicFile(filesDir.resolve("backup_restore_journal.json"))
            when (call.method) {
                "loadRestoreJournal" -> {
                    if (!journalFile.baseFile.exists()) {
                        result.success(null)
                    } else {
                        try {
                            result.success(journalFile.openRead().bufferedReader().use { it.readText() })
                        } catch (error: Exception) {
                            result.error("JOURNAL_READ_FAILED", "Restore journal could not be read.", error.message)
                        }
                    }
                }
                "saveRestoreJournal" -> {
                    val journal = call.argument<String>("journal")
                    if (journal == null) {
                        result.error("INVALID_ARGUMENT", "Restore journal is required.", null)
                    } else {
                        var output: FileOutputStream? = null
                        try {
                            val stream = journalFile.startWrite()
                            output = stream
                            stream.write(journal.toByteArray(Charsets.UTF_8))
                            stream.fd.sync()
                            journalFile.finishWrite(stream)
                            result.success(null)
                        } catch (error: Exception) {
                            output?.let(journalFile::failWrite)
                            result.error("JOURNAL_WRITE_FAILED", "Restore journal could not be saved.", error.message)
                        }
                    }
                }
                "clearRestoreJournal" -> {
                    try {
                        journalFile.delete()
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("JOURNAL_CLEAR_FAILED", "Restore journal could not be cleared.", error.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
