package com.v2net

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.net.VpnService
import android.util.Log
import android.app.Activity

class MainActivity : FlutterActivity(), VpnConnection {

    private var pendingVpnCallback: ((Result<VpnResult>) -> Unit)? = null
    private var pendingConfig: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        VpnConnection.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
    }

    override fun start(configJson: String, callback: (Result<VpnResult>) -> Unit) {
        Log.d("VPN_BRIDGE", "Requesting VPN start with dynamic config...")

        val intent = VpnService.prepare(this)

        if (intent != null) {
            pendingVpnCallback = callback
            pendingConfig = configJson
            startActivityForResult(intent, 24)
        } else {
            val serviceIntent = android.content.Intent(applicationContext, com.v2net.V2RayVpnService::class.java)
            serviceIntent.putExtra("XRAY_CONFIG", configJson)
            startService(serviceIntent)

            callback(Result.success(VpnResult(successful = true)))
        }
    }

    override fun stop(callback: (Result<VpnResult>) -> Unit) {
        Log.d("VPN_BRIDGE", "Stopping VPN...")

        val serviceIntent = android.content.Intent(applicationContext, com.v2net.V2RayVpnService::class.java)
        serviceIntent.action = "ACTION_STOP_VPN"
        startService(serviceIntent)

        callback(Result.success(VpnResult(successful = true)))
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == 24) {
            if (resultCode == Activity.RESULT_OK) {
                Log.d("VPN_BRIDGE", "Permission granted, starting service")

                val config = pendingConfig
                if (config != null) {
                    val serviceIntent = android.content.Intent(applicationContext, com.v2net.V2RayVpnService::class.java)
                    serviceIntent.putExtra("XRAY_CONFIG", config)
                    startService(serviceIntent)

                    pendingVpnCallback?.invoke(Result.success(VpnResult(successful = true)))
                } else {
                    Log.e("VPN_BRIDGE", "Error: pendingConfig is null")
                    pendingVpnCallback?.invoke(Result.success(VpnResult(successful = false, hasError = true, error = "Config lost")))
                }
            } else {
                Log.d("VPN_BRIDGE", "Permission denied by user")
                pendingVpnCallback?.invoke(Result.success(VpnResult(successful = false)))
            }
            pendingVpnCallback = null
            pendingConfig = null
        }
    }
}