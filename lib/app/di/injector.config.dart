// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:talker_flutter/talker_flutter.dart' as _i207;

import '../../features/subscriptions/data/subscription_parser/subscription_parser_service.dart'
    as _i302;
import '../../features/vpn/cubit/vpn_cubit.dart' as _i364;
import '../../features/vpn/data/vpn_api.g.dart' as _i482;
import '../../features/vpn/data/vpn_repository.dart' as _i1056;
import '../../features/vpn/data/vpn_status_receiver.dart' as _i915;
import 'logger_module.dart' as _i987;
import 'vpn_module.dart' as _i731;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final loggerModule = _$LoggerModule();
    final vpnModule = _$VpnModule();
    gh.lazySingleton<_i207.Talker>(() => loggerModule.talker);
    gh.lazySingleton<_i482.VpnConnection>(() => vpnModule.vpnConnection);
    gh.lazySingleton<_i915.VpnStatusReceiver>(
      () => vpnModule.vpnStatusReceiver,
    );
    gh.lazySingleton<_i302.SubscriptionParserService>(
      () => _i302.SubscriptionParserService(gh<_i207.Talker>()),
    );
    gh.lazySingleton<_i1056.VpnRepository>(
      () => _i1056.VpnRepository(
        gh<_i207.Talker>(),
        gh<_i482.VpnConnection>(),
        gh<_i915.VpnStatusReceiver>(),
      ),
    );
    gh.lazySingleton<_i364.VpnCubit>(
      () => _i364.VpnCubit(
        repository: gh<_i1056.VpnRepository>(),
        talker: gh<_i207.Talker>(),
      ),
    );
    return this;
  }
}

class _$LoggerModule extends _i987.LoggerModule {}

class _$VpnModule extends _i731.VpnModule {}
