# Pigeon VPN bridge
generate-vpn-api:
	dart run pigeon \
	--input pigeons/vpn_api.dart \
	--copyright_header pigeons/copyright_header.txt \
	--dart_out lib/features/vpn/data/vpn_api.g.dart \
	--kotlin_out android/app/src/main/kotlin/com/v2net/VpnApi.g.kt \
	--kotlin_package "com.v2net" \
	--swift_out ios/Runner/VpnApi.g.swift

# Remove generated Pigeon outputs
clean-vpn-api:
	rm -f lib/features/vpn/data/vpn_api.g.dart
	rm -f android/app/src/main/kotlin/com/v2net/VpnApi.g.kt
	rm -f ios/Runner/VpnApi.g.swift

# Native tunnel core (Xray-core + tun2socks), shared by Android/iOS/desktop.
# See ../v2net-core/README.md.
build-core-android:
	$(MAKE) -C ../v2net-core bind-android

# iOS: build the gomobile xcframework and copy it next to the app (mirrors how
# bind-android writes straight into android/app/libs/). Result lands in
# ios/Frameworks/v2netcore.xcframework, linked by the Runner + PacketTunnel targets.
build-core-ios:
	$(MAKE) -C ../v2net-core bind-ios
	rm -rf ios/Frameworks/v2netcore.xcframework
	mkdir -p ios/Frameworks
	cp -R ../v2net-core/v2netcore.xcframework ios/Frameworks/
