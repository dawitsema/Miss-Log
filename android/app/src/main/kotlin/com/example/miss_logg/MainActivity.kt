// File: android/app/src/main/kotlin/.../MainActivity.kt
package com.example.volumebooster

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "com.example.volumebooster/channel"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "startMonitoring" -> {
            // nothing to do—receiver is already registered statically
            result.success("Monitoring active")
          }
          "setThresholds" -> {
            val max = call.argument<Int>("maxCalls") ?: 3
            val windowMin = call.argument<Int>("windowMin") ?: 5
            CallReceiver.maxCalls = max
            CallReceiver.windowMillis = windowMin * 60_000L
            result.success("Thresholds updated")
          }
          else -> result.notImplemented()
        }
      }
  }
}
