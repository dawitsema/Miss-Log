// File: android/app/src/main/kotlin/.../CallReceiver.kt
package com.example.volumebooster

import android.content.*
import android.media.AudioManager
import android.os.Build
import android.telephony.TelephonyManager
import java.util.*
import kotlin.collections.HashMap

class CallReceiver : BroadcastReceiver() {

    companion object {
        // Will be set from Flutter through MethodChannel
        @Volatile var maxCalls = 3
        @Volatile var windowMillis: Long = 5 * 60 * 1000 // 5 min default

        // phoneNumber -> deque of epochMillis
        private val calls: MutableMap<String, ArrayDeque<Long>> = HashMap()

        private fun purgeOld(tsQueue: ArrayDeque<Long>, now: Long) {
            while (tsQueue.isNotEmpty() && now - tsQueue.peekFirst() > windowMillis) {
                tsQueue.removeFirst()
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        val stateStr = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        if (stateStr != TelephonyManager.EXTRA_STATE_RINGING) return

        // Sometimes EXTRA_INCOMING_NUMBER is null on Android 10+. Live with it or use TelecomManager.defaultDialer
        val incoming = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: "UNKNOWN"
        val now = System.currentTimeMillis()

        val q = calls.getOrPut(incoming) { ArrayDeque() }
        purgeOld(q, now)
        q.addLast(now)

        if (q.size > maxCalls) boostVolume(context)
    }

    private fun boostVolume(ctx: Context) {
        val am = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val stream = AudioManager.STREAM_RING // or STREAM_MUSIC, up to you
        val maxVol = am.getStreamMaxVolume(stream)
        am.setStreamVolume(stream, maxVol, AudioManager.FLAG_SHOW_UI)
    }
}
