import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';

@module
abstract class LoggerModule {
  @lazySingleton
  Talker get talker => TalkerFlutter.init(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: true,
      maxHistoryItems: 100,
    ),
  );
}
