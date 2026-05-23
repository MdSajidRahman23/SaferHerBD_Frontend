import 'package:flutter_test/flutter_test.dart';
import 'package:safeher_bangladesh/utils/constants.dart';

void main() {
  test('API base URLs are configured', () {
    expect(ApiConfig.baseUrl, isNotEmpty);
    expect(ApiConfig.mlBaseUrl, isNotEmpty);
  });

  test('SOS endpoints are configured', () {
    expect(ApiConfig.sosTrigger, contains('/sos/trigger'));
    expect(ApiConfig.sosHistory, contains('/sos/history'));
  });
}
