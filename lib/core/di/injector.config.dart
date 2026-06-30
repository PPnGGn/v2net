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

import '../platform/vpn_api.g.dart' as _i1047;
import '../repositories/vpn_repository.dart' as _i230;
import '../services/vpn_service/vpn_service_cubit.dart' as _i822;
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
    gh.lazySingleton<_i1047.VpnConnection>(() => vpnModule.vpnConnection);
    gh.lazySingleton<_i230.IVpnRepository>(
      () => _i230.VpnRepositoryImpl(
        gh<_i207.Talker>(),
        gh<_i1047.VpnConnection>(),
      ),
    );
    gh.lazySingleton<_i822.VpnServiceCubit>(
      () => _i822.VpnServiceCubit(
        repository: gh<_i230.IVpnRepository>(),
        talker: gh<_i207.Talker>(),
      ),
    );
    return this;
  }
}

class _$LoggerModule extends _i987.LoggerModule {}

class _$VpnModule extends _i731.VpnModule {}
