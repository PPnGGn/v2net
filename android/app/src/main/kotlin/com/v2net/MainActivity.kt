package com.v2net

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.util.Log

// 1. Добавляем VpnConnection через запятую
class MainActivity : FlutterActivity(), VpnConnection {

    // 2. Регистрируем наш канал связи при запуске движка
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        VpnConnection.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
    }

    // 3. Реализуем метод start
    override fun start(): VpnResult {
        Log.d("VPN_BRIDGE", "Команда start() получена нативом!")

        val result = VpnResult()
        return VpnResult(successful = true)
    }

    // 4. Реализуем метод stop
    override fun stop(): VpnResult {
        Log.d("VPN_BRIDGE", "Команда stop() получена нативом!")

        val result = VpnResult()
        return VpnResult(successful = true)
    }
}