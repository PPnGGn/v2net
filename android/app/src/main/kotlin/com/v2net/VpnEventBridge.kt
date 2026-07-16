package com.v2net

import android.os.Handler
import android.os.Looper
import android.util.Log

// Lets V2RayVpnService reach the Flutter engine it has no direct handle to.
object VpnEventBridge {

    @Volatile
    var receiver: ConnectionReceiver? = null

    // Pigeon channels require the main thread.
    private val mainHandler = Handler(Looper.getMainLooper())

    fun notifyStatus(connected: Boolean) {
        val receiver = this.receiver
        if (receiver == null) {
            Log.w("VPN_BRIDGE", "No Flutter engine attached, status update dropped: connected=$connected")
            return
        }
        mainHandler.post {
            receiver.onStatusChanged(VpnMessage(connected = connected)) { result ->
                result.onFailure { e ->
                    Log.e("VPN_BRIDGE", "Failed to deliver status to Dart: ${e.message}")
                }
            }
        }
    }
}
