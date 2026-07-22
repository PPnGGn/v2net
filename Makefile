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


build-core-android:
	$(MAKE) -C ../v2net-core bind-android


build-core-ios:
	$(MAKE) -C ../v2net-core bind-ios
	rm -rf ios/Frameworks/v2netcore.xcframework
	mkdir -p ios/Frameworks
	cp -R ../v2net-core/v2netcore-ios.xcframework ios/Frameworks/v2netcore.xcframework


build-core-mac:
	$(MAKE) -C ../v2net-core bind-mac
	rm -rf macos/Frameworks/v2netcore-mac.xcframework
	mkdir -p macos/Frameworks
	cp -R ../v2net-core/v2netcore-mac.xcframework macos/Frameworks/
