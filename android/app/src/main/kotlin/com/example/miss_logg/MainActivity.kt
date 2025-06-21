package com.example.volumebooster

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.provider.CallLog
import android.provider.Settings
import android.widget.Toast
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.volumebooster/channel"
    private val targetNumber = "+251962484250"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "startMonitoring") {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.READ_CALL_LOG,
                        Manifest.permission.MODIFY_AUDIO_SETTINGS,
                        Manifest.permission.WRITE_SETTINGS
                    ),
                    0
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.System.canWrite(this)) {
                    val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                    intent.data = android.net.Uri.parse("package:$packageName")
                    startActivity(intent)
                }

                registerReceiver(CallLogReceiver(), IntentFilter("android.intent.action.PHONE_STATE"))
                result.success("Monitoring started")
            } else {
                result.notImplemented()
            }
        }
    }

    inner class CallLogReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            context ?: return
            val now = System.currentTimeMillis()
            val tenMinutesAgo = now - (10 * 60 * 1000)

            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                null,
                "${CallLog.Calls.NUMBER} = ? AND ${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} > ?",
                arrayOf(targetNumber, CallLog.Calls.MISSED_TYPE.toString(), tenMinutesAgo.toString()),
                null
            )

            cursor?.use {
                if (it.count >= 2) {
                    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_RING)
                    audioManager.setStreamVolume(AudioManager.STREAM_RING, maxVolume, 0)
                    Toast.makeText(context, "Volume raised due to 3 missed calls", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}
