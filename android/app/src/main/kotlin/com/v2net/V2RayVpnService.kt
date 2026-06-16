package com.v2net

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

class V2RayVpnService : VpnService() {

    // Descriptor for the TUN interface
    private var localTunnel: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Handle service stop request
        if (intent?.action == "ACTION_STOP_VPN") {
            Log.d("VPN_SERVICE", "Stopping service by request...")

            localTunnel?.close()
            localTunnel = null
            stopSelf()

            return START_NOT_STICKY
        }

        Log.d("VPN_SERVICE", "Starting service...")
        setupVpn()

        // Ensure service is restarted if killed by the system
        return START_STICKY
    }

    private fun setupVpn() {
        Log.d("VPN_SERVICE", "Configuring tunnel...")

        localTunnel?.close()
        localTunnel = null

        try {
            // Route all traffic (0.0.0.0/0) through the interface
            localTunnel = Builder()
                .addAddress("10.0.0.2", 24)
                .addDnsServer("8.8.8.8")
                .addRoute("0.0.0.0", 0)
                .setSession("v2net")
                .establish()

            Log.d("VPN_SERVICE", "Tunnel established")

        } catch (e: Exception) {
            Log.e("VPN_SERVICE", "Failed to create interface: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Ensure the descriptor is closed when service is destroyed
        localTunnel?.close()
        localTunnel = null
    }
}