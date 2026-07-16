import 'dart:convert';

class XrayConfigBuilder {
  // Builds a full Xray client config (VLESS + Reality) for a single server.
  String buildVlessReality({
    required String uuid, required String address, required int port, required String sni,
    required String pbk, required String sid, required String fp, required String flow, required String title,
  }) {
    final Map<String, dynamic> config = {
      "dns": {"queryStrategy": "UseIP", "servers": ["https://8.8.8.8/dns-query", "https://8.8.4.4/dns-query"]},
      "inbounds": [
        {"listen": "127.0.0.1", "port": 10808, "protocol": "socks", "settings": {"auth": "noauth", "udp": true, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls"], "enabled": true, "routeOnly": false}, "tag": "socks"},
        {"listen": "127.0.0.1", "port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}
      ],
      "log": {"loglevel": "info"},
      "outbounds": [
        {"protocol": "vless", "settings": {"vnext": [{"address": address, "port": port, "users": [{"encryption": "none", "flow": flow.isNotEmpty ? flow : "xtls-rprx-vision", "id": uuid, "level": 8}]}]}, "streamSettings": {"network": "tcp", "realitySettings": {"allowInsecure": false, "fingerprint": fp.isNotEmpty ? fp : "chrome", "publicKey": pbk, "serverName": sni, "shortId": sid, "show": false}, "security": "reality", "tcpSettings": {"header": {"type": "none"}}}, "tag": "proxy"},
        {"protocol": "freedom", "settings": {"domainStrategy": "UseIP"}, "tag": "direct"},
        {"protocol": "blackhole", "settings": {"response": {"type": "http"}}, "tag": "block"}
      ],
      "remarks": title,
      "routing": {"domainMatcher": "hybrid", "domainStrategy": "IPIfNonMatch", "rules": [{"outboundTag": "direct", "protocol": ["bittorrent"], "type": "field"}]}
    };
    return jsonEncode(config);
  }
}
