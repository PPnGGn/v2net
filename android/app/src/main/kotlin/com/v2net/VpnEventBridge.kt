package com.v2net

import android.os.Handler
import android.os.Looper
import android.util.Log

// Lets V2RayVpnService reach the Flutter engine it has no direct handle to.
// Also holds the last pushed status so MainActivity.getStatus() can answer a
// resume query even while the app was backgrounded.
object VpnEventBridge {

    @Volatile
    var receiver: VpnEventReceiver? = null

    @Volatile
    private var lastStatus: VpnStatus = VpnStatus.DISCONNECTED

    @Volatile
    private var lastError: String? = null

    // Pigeon channels require the main thread.
    private val mainHandler = Handler(Looper.getMainLooper())

    fun currentStatus(): VpnStatusMessage = VpnStatusMessage(lastStatus, lastError)

    fun notifyStatus(status: VpnStatus, error: String? = null) {
        lastStatus = status
        lastError = error

        val receiver = this.receiver
        if (receiver == null) {
            Log.w("VPN_BRIDGE", "No Flutter engine attached, status update cached: $status")
            return
        }
        mainHandler.post {
            receiver.onStatusChanged(VpnStatusMessage(status, error)) { result ->
                result.onFailure { e ->
                    Log.e("VPN_BRIDGE", "Failed to deliver status to Dart: ${e.message}")
                }
            }
        }
    }
}
