package com.v2net

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

// Go-биндинг v2netcore (gomobile).
import v2netcore.V2netcore

class V2RayVpnService : VpnService() {

    private var localTunnel: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "ACTION_STOP_VPN") {
            Log.d("VPN_SERVICE", "Stopping service by request...")
            stopVpn()
            return START_NOT_STICKY
        }

        // JSON-конфиг из MainActivity (extra XRAY_CONFIG).
        val configJson = intent?.getStringExtra("XRAY_CONFIG")
        if (configJson == null) {
            Log.e("VPN_SERVICE", "Config is missing. Aborting.")
            return START_NOT_STICKY
        }

        Log.d("VPN_SERVICE", "Starting service and core...")
        setupVpn(configJson)
        
        // START_STICKY: ОС перезапустит сервис после kill по памяти.
        // Без Intent в extras перезапуск упадёт — нужна отдельная обработка (TODO).
        return START_STICKY
    }

    private fun setupVpn(configJson: String) {
        try {
            // 1. Старт Xray: JSON -> protobuf -> inbound (порт из конфига, сейчас 10808).
            // Битый JSON — exception из Go, ловим в catch ниже.
            V2netcore.startXray(configJson)
            Log.d("VPN_SERVICE", "Xray core started successfully.")

            // 2. TUN-интерфейс.
            localTunnel = Builder()
                .addAddress("10.0.0.2", 24) // адрес устройства в туннеле
                .addDnsServer("8.8.8.8")    // DNS внутри туннеля, иначе утечки
                .addRoute("0.0.0.0", 0)     // весь IPv4
                .addDisallowedApplication(packageName) // иначе Xray ходит в свой же TUN — петля
                                                      // packageName = "com.v2net"
                .setSession("v2net")        // имя в настройках VPN Android
                .setMtu(1500)               // без MTU TCP фрагментируется, скорость падает
                .establish()

            // 3. fd TUN-устройства — через него читаются сырые IP-пакеты.
            val fd = localTunnel?.fd ?: throw Exception("Failed to get TUN FD")

            // 4. tun2socks: fd -> SOCKS на localhost:10808 (inbound Xray).
            // toLong() — gomobile мапит Go int в Kotlin Long.
            V2netcore.startTun(fd.toLong(), 10808L)
            Log.d("VPN_SERVICE", "Tun2Socks linked to fd: $fd on port 10808.")

        } catch (e: Exception) {
            Log.e("VPN_SERVICE", "Critical error in setupVpn: ${e.message}")
            stopVpn()
        }
    }

    private fun stopVpn() {
        Log.d("VPN_SERVICE", "Shutting down everything...")
        
        try {
            // tun2socks + xray; иначе 10808 останется занят.
            V2netcore.stopAll()
        } catch (e: Exception) {
            Log.e("VPN_SERVICE", "Failed to stop core: ${e.message}")
        }

        // закрываем TUN, трафик снова идёт мимо VPN
        localTunnel?.close()
        localTunnel = null
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }
}