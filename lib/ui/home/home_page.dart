import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:v2net/core/di/injector.dart';
import 'package:v2net/core/cubits/vpn/vpn_cubit.dart';
import 'package:v2net/entities/models/vpn_server.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // MVP test server
  VpnServer get _testServer => const VpnServer(
    id: 'test_1',
    countryCode: 'DE',
    title: '🇩🇪 DE 🔴 [#1]',
    // full provider JSON
    rawCode: '''{
    "dns": {
        "queryStrategy": "UseIP",
        "servers": [
            "https://8.8.8.8/dns-query",
            "https://8.8.4.4/dns-query"
        ]
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
    "meta": null,
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
                        "address": "cherry-nll-01.live",
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
                "realitySettings": {
                    "allowInsecure": false,
                    "fingerprint": "firefox",
                    "publicKey": "LT_0j3zQkaqgtJHvyaG24xz0IfmXUswVCTeC75Qsgjo",
                    "serverName": "storage.yandex.net",
                    "shortId": "0905b6e16602f326",
                    "show": false
                },
                "security": "reality",
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
    "remarks": "🇳🇱⚡Нидерланды",
    "routing": {
        "domainMatcher": "hybrid",
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "outboundTag": "direct",
                "protocol": [
                    "bittorrent"
                ],
                "type": "field"
            },
            {
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
                ],
                "outboundTag": "direct",
                "type": "field"
            }
        ]
    }
}
''', subscriptionId: '',
  );

  @override
  Widget build(BuildContext context) {
    final cubit = getIt<VpnCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('V2Net MVP'), centerTitle: true),
      body: Center(
        child: BlocBuilder<VpnCubit, VpnState>(
          bloc: cubit,
          builder: (context, state) {
            return state.when(
              initial: () => _buildConnectState(cubit),
              disconnected: () => _buildConnectState(cubit),
              connecting: () => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Запуск ядра Xray...'),
                ],
              ),
              connected: (server) => _buildConnectedState(cubit, server),
              error: (message) => _buildErrorState(cubit, message),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConnectState(VpnCubit cubit) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: () => cubit.connect(_testServer),
          child: const Text('ПОДКЛЮЧИТЬСЯ', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildConnectedState(VpnCubit cubit, VpnServer server) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          'Подключено к:\n${server.title}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => cubit.disconnect(),
          child: const Text('ОТКЛЮЧИТЬСЯ', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildErrorState(VpnCubit cubit, String message) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'Ошибка подключения:\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => cubit.connect(_testServer),
            child: const Text('ПОВТОРИТЬ ПОПЫТКУ'),
          ),
        ],
      ),
    );
  }
}
