# Pigeon VPN bridge
generate-vpn-api:
	dart run pigeon \
	--input pigeons/vpn_api.dart \
	--copyright_header pigeons/copyright_header.txt \
	--dart_out lib/features/vpn/data/vpn_api.g.dart \
	--kotlin_out android/app/src/main/kotlin/com/v2net/VpnApi.g.kt \
	--kotlin_package "com.v2net"

# Remove generated Pigeon outputs
clean-vpn-api:
	rm -f lib/features/vpn/data/vpn_api.g.dart
	rm -f android/app/src/main/kotlin/com/v2net/VpnApi.g.kt

# Native tunnel core (Xray-core + tun2socks), shared by Android/iOS/desktop.
# See ../v2net-core/README.md.
build-core-android:
	$(MAKE) -C ../v2net-core bind-android
