import 'package:v2net/core/common/result.dart';
import 'package:v2net/entities/models/vpn_server.dart';

abstract class ISubscriptionParserService{
  Future<Result<List<VpnServer>>> parseFromUrl(String url);
}