package com.v2net

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

// v2netcore gomobile bindings
import v2netcore.V2netcore

class V2RayVpnService : VpnService() {

    private var localTunnel: ParcelFileDescriptor? = null

    // guard duplicate stop (onRevoke + onDestroy)
    private var isStopping = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "ACTION_STOP_VPN") {
            Log.d("VPN_SERVICE", "Stopping service by request...")
            stopVpn()
            return START_NOT_STICKY
        }

        val configJson = intent?.getStringExtra("XRAY_CONFIG")
        if (configJson == null) {
            Log.e("VPN_SERVICE", "Config is missing. Aborting.")
            return START_NOT_STICKY
        }

        Log.d("VPN_SERVICE", "Starting service and core...")
        isStopping = false
        setupVpn(configJson)

        return START_STICKY
    }

    private fun setupVpn(configJson: String) {
        try {
            V2netcore.startXray(configJson)
            Log.d("VPN_SERVICE", "Xray core started successfully.")

            localTunnel = Builder()
                .addAddress("10.0.0.2", 24)
                .addDnsServer("8.8.8.8")
                .addRoute("0.0.0.0", 0)
                .addDisallowedApplication(packageName)
                .setSession("v2net")
                .setMtu(1500)
                .establish()

            val fd = localTunnel?.detachFd() ?: throw Exception("Failed to get TUN FD")

            V2netcore.startTun(fd.toLong(), 10808L)
            Log.d("VPN_SERVICE", "Tun2Socks linked to fd: $fd on port 10808.")

            VpnEventBridge.notifyStatus(true)

        } catch (e: Exception) {
            Log.e("VPN_SERVICE", "Critical error in setupVpn: ${e.message}")
            stopVpn()
        }
    }

    // another VPN took over
    override fun onRevoke() {
        Log.w("VPN_SERVICE", "VPN revoked by system (another VPN started). Emergency shutdown.")
        stopVpn()
        super.onRevoke()
    }

    private fun stopVpn() {
        if (isStopping) return
        isStopping = true

        Log.d("VPN_SERVICE", "Shutting down everything...")

        try {
            // core closes the TUN fd on the native side
            V2netcore.stopAll()
        } catch (e: Exception) {
            Log.e("VPN_SERVICE", "Failed to stop core: ${e.message}")
        }

        localTunnel = null

        // single call site: covers explicit stop, onRevoke, onDestroy, setupVpn failure
        VpnEventBridge.notifyStatus(false)

        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }
}