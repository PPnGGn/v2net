import 'package:v2net/core/models/stored_subscription/stored_subscription.dart';

abstract interface class SubscriptionStorage {
  Future<List<StoredSubscription>> loadAll();
  Future<void> save(StoredSubscription subscription);
  Future<void> delete(String subscriptionId);
}
