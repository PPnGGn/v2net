import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists which server the user picked as active, across launches.
@lazySingleton
class SelectedServerStore {
  static const _subscriptionKey = 'selected_subscription_id';
  static const _serverKey = 'selected_server_id';

  final SharedPreferences _prefs;

  SelectedServerStore(this._prefs);

  (String subscriptionId, String serverId)? load() {
    final subscriptionId = _prefs.getString(_subscriptionKey);
    final serverId = _prefs.getString(_serverKey);
    if (subscriptionId == null || serverId == null) return null;
    return (subscriptionId, serverId);
  }

  Future<void> save(String subscriptionId, String serverId) async {
    await _prefs.setString(_subscriptionKey, subscriptionId);
    await _prefs.setString(_serverKey, serverId);
  }

  Future<void> clear() async {
    await _prefs.remove(_subscriptionKey);
    await _prefs.remove(_serverKey);
  }
}
