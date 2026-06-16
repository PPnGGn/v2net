package com.v2net

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.util.Log

import android.net.VpnService
import android.content.Intent
import android.app.Activity

// Native bridge for Flutter (Pigeon)
class MainActivity : FlutterActivity(), VpnConnection {

    private var pendingVpnCallback: ((Result<VpnResult>) -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Initialize communication channel
        VpnConnection.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
    }


    override fun start(callback: (Result<VpnResult>) -> Unit) {
        Log.d("VPN_BRIDGE", "Starting VPN (Async)...")

        // Check for system VPN permissions
        val intent: Intent? = VpnService.prepare(this)

        if (intent != null) {

            pendingVpnCallback = callback

            // No permission, request from system.
            // 24 is our requestCode to handle the result.
            startActivityForResult(intent, 24)
        } else {
            // Permission already granted, start service
            val serviceIntent = Intent(this, V2RayVpnService::class.java)
            startService(serviceIntent)

            callback(Result.success(VpnResult(successful = true)))
        }
    }

    override fun stop(callback: (Result<VpnResult>) -> Unit) {
        Log.d("VPN_BRIDGE", "Stopping VPN...")

        // Notify service to stop itself
        val serviceIntent = Intent(this, V2RayVpnService::class.java)
        serviceIntent.action = "ACTION_STOP_VPN"
        startService(serviceIntent)

        callback(Result.success(VpnResult(successful = true)))
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        // Handle VPN permission request result
        if (requestCode == 24) {
            if (resultCode == Activity.RESULT_OK) {
                Log.d("VPN_BRIDGE", "Permission granted, starting service")
                val serviceIntent = Intent(this, V2RayVpnService::class.java)
                startService(serviceIntent)

                pendingVpnCallback?.invoke(Result.success(VpnResult(successful = true)))
            } else {
                Log.d("VPN_BRIDGE", "Permission denied by user")

                pendingVpnCallback?.invoke(Result.success(VpnResult(successful = false)))
            }


            pendingVpnCallback = null
        }
    }
}