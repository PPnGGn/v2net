package com.v2net

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.util.Log
import android.net.VpnService
import android.content.Intent
import android.app.Activity

class MainActivity : FlutterActivity(), VpnConnection {

    private var pendingVpnCallback: ((Result<VpnResult>) -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Pigeon-канал Flutter <-> Kotlin
        VpnConnection.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
    }

    // Тестовый конфиг, потом уйдёт в репозиторий/бекенд.
    private fun getTestConfig(): String {
        return """
        {
          "dns": {
            "servers": [
              "https://8.8.8.8/dns-query",
              "https://8.8.4.4/dns-query"
            ],
            "queryStrategy": "UseIP"
          },
          "inbounds": [
            {
              "listen": "127.0.0.1",
              "port": 10808,
              "protocol": "socks",
              "settings": {
                "auth": "noauth",
                "udp": true,
                "userLevel": 8
              },
              "sniffing": {
                "destOverride": [
                  "http",
                  "tls"
                ],
                "enabled": true,
                "routeOnly": false
              },
              "tag": "socks"
            },
            {
              "listen": "127.0.0.1",
              "port": 10809,
              "protocol": "http",
              "settings": {
                "userLevel": 8
              },
              "tag": "http"
            }
          ],
          "log": {
            "loglevel": "info"
          },
          "outbounds": [
            {
              "mux": {
                "concurrency": -1,
                "enabled": false
              },
              "protocol": "vless",
              "settings": {
                "vnext": [
                  {
                    "address": "nl01-cherry.online",
                    "port": 8443,
                    "users": [
                      {
                        "encryption": "none",
                        "flow": "xtls-rprx-vision",
                        "id": "a96547a3-89c1-435d-9fe0-9b069996bd3d",
                        "level": 8
                      }
                    ]
                  }
                ]
              },
              "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                  "allowInsecure": false,
                  "fingerprint": "firefox",
                  "publicKey": "LT_0j3zQkaqgtJHvyaG24xz0IfmXUswVCTeC75Qsgjo",
                  "serverName": "storage.yandex.net",
                  "shortId": "6f15101ff2cc4887",
                  "show": false
                },
                "tcpSettings": {
                  "header": {
                    "type": "none"
                  }
                }
              },
              "tag": "proxy"
            },
            {
              "protocol": "freedom",
              "settings": {
                "domainStrategy": "UseIP"
              },
              "tag": "direct"
            },
            {
              "protocol": "blackhole",
              "settings": {
                "response": {
                  "type": "http"
                }
              },
              "tag": "block"
            }
          ],
          "routing": {
            "domainStrategy": "IPIfNonMatch",
            "domainMatcher": "hybrid",
            "rules": [
              {
                "type": "field",
                "protocol": [
                  "bittorrent"
                ],
                "outboundTag": "direct"
              },
              {
                "type": "field",
                "outboundTag": "direct",
                "domain": [
                  "domain:ru",
                  "domain:xn--p1ai",
                  "domain:1cfresh.com",
                  "domain:2gis.by",
                  "domain:2gis.com",
                  "domain:2gis.com.cy",
                  "domain:alfa-bank.com",
                  "domain:alfabank.com",
                  "domain:alfafinance.biz",
                  "domain:alfafx.com",
                  "domain:alfaprivate.com",
                  "domain:beta-bank.com",
                  "domain:gazprombank.tech",
                  "domain:investalfabank.com",
                  "domain:moex.com",
                  "domain:tbank-online.com",
                  "domain:tochka.com",
                  "domain:tochka-tech.com",
                  "domain:vtb.com",
                  "domain:vtb.digital",
                  "domain:vtb.promo",
                  "domain:vtb24.com",
                  "domain:vtbrussia.com",
                  "domain:avito.st",
                  "domain:lenta.com",
                  "domain:megamarket.tech",
                  "domain:okko.tv",
                  "domain:ozonusercontent.com",
                  "domain:premier.one",
                  "domain:wildberries.by",
                  "domain:wbstatic.net",
                  "domain:youla.io",
                  "domain:userapi.com",
                  "domain:vk.com",
                  "domain:vk-portal.net",
                  "domain:yads.tech",
                  "domain:yandex",
                  "domain:yandex-bank.net",
                  "domain:yandex.aero",
                  "domain:yandex.az",
                  "domain:yandex.by",
                  "domain:yandex.cloud",
                  "domain:yandex.co.il",
                  "domain:yandex.com",
                  "domain:yandex.com.ge",
                  "domain:yandex.eu",
                  "domain:yandex.fr",
                  "domain:yandex.jobs",
                  "domain:yandex.kg",
                  "domain:yandex.kz",
                  "domain:yandex.net",
                  "domain:yandex.org",
                  "domain:yandexadexchange.net",
                  "domain:yandexcloud.net",
                  "domain:yandexcom.net",
                  "domain:yandexmetrica.com",
                  "domain:yandexwebcache.net",
                  "domain:yandexwebcache.org",
                  "domain:yastat.net",
                  "domain:yastatic.net",
                  "domain:gismeteo.com",
                  "domain:lmru.tech",
                  "domain:mradx.net",
                  "domain:tildaapi.com",
                  "domain:kontur.host"
                ]
              }
            ]
          }
        }
        """.trimIndent()
    }

    override fun start(callback: (Result<VpnResult>) -> Unit) {
        Log.d("VPN_BRIDGE", "Requesting VPN start...")

        val intent: Intent? = VpnService.prepare(this)

        if (intent != null) {
            pendingVpnCallback = callback
            // нет разрешения — системный диалог
            startActivityForResult(intent, 24)
        } else {
            // разрешение уже есть
            val serviceIntent = Intent(this, V2RayVpnService::class.java).apply {
                putExtra("XRAY_CONFIG", getTestConfig())
            }
            startService(serviceIntent)
            callback(Result.success(VpnResult(successful = true)))
        }
    }

    override fun stop(callback: (Result<VpnResult>) -> Unit) {
        Log.d("VPN_BRIDGE", "Stopping VPN...")
        val serviceIntent = Intent(this, V2RayVpnService::class.java)
        serviceIntent.action = "ACTION_STOP_VPN"
        startService(serviceIntent)
        callback(Result.success(VpnResult(successful = true)))
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        // результат VpnService.prepare()
        if (requestCode == 24) {
            if (resultCode == Activity.RESULT_OK) {
                Log.d("VPN_BRIDGE", "Permission granted, starting service")

                // разрешение получено, стартуем сервис с конфигом
                val serviceIntent = Intent(this, V2RayVpnService::class.java).apply {
                    putExtra("XRAY_CONFIG", getTestConfig())
                }
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