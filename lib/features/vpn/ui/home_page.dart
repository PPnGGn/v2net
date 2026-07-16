import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:v2net/app/di/injector.dart';
import 'package:v2net/core/models/vpn_server.dart';
import 'package:v2net/features/vpn/cubit/vpn_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // "geosite:category-ru" stripped from routing rules — geosite.dat isn't
  // bundled yet, xray would fail to start on that rule.
  VpnServer get _testServer => const VpnServer(
    id: 'test_hu_1',
    subscriptionId: '',
    countryCode: 'HU',
    title: '🇭🇺⚡️Венгрия',
    // full provider JSON
    rawCode: r'''{
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
            "address": "45.195.111.15",
            "port": 443,
            "users": [
              {
                "encryption": "none",
                "flow": "xtls-rprx-vision",
                "id": "f2976bce-047a-49a4-91ec-8f18d603475d",
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
          "publicKey": "7zd9mJilgjOrg_ohtw23Vmio-pdnYqeP_r-kiWt87Cg",
          "serverName": "5post-gate.x5.ru",
          "shortId": "f4b4a6365558ea2e",
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
  "remarks": "🇭🇺⚡️Венгрия",
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "domainMatcher": "hybrid",
    "rules": [
      {
        "type": "field",
        "network": "udp",
        "port": "443",
        "outboundTag": "block"
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
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "direct"
      }
    ]
  }
}
''',
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
