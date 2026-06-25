# Pigeon VPN bridge
generate-vpn-api:
	dart run pigeon \
	--input pigeons/vpn_api.dart \
	--copyright_header pigeons/copyright_header.txt \
	--dart_out lib/core/platform/vpn_api.g.dart \
	--kotlin_out android/app/src/main/kotlin/com/v2net/VpnApi.g.kt \
	--kotlin_package "com.v2net"

# Remove generated Pigeon outputs
clean-vpn-api:
	rm -f lib/core/platform/vpn_api.g.dart
	rm -f android/app/src/main/kotlin/com/v2net/VpnApi.g.kt
