import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/api/api_client.dart';
import 'package:poker_client/utils/jwt_helper.dart';

void main() {
  group('JWT Helper Tests', () {
    const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwbGF5ZXJJZCI6IjU1MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMCIsInVzZXJuYW1lIjoiYWxpY2VfcG9rZXIifQ.signature';

    test('should decode valid JWT payload correctly', () {
      final decoded = JwtHelper.decode(testToken);
      expect(decoded, isNotNull);
      expect(decoded!['playerId'], '550e8400-e29b-41d4-a716-446655440000');
      expect(decoded['username'], 'alice_poker');
    });

    test('should extract playerId and username correctly', () {
      final playerId = JwtHelper.getPlayerId(testToken);
      final username = JwtHelper.getUsername(testToken);

      expect(playerId, '550e8400-e29b-41d4-a716-446655440000');
      expect(username, 'alice_poker');
    });

    test('should return null for invalid JWT formats', () {
      expect(JwtHelper.decode('invalid_token'), isNull);
      expect(JwtHelper.getPlayerId('a.b'), isNull);
    });
  });

  group('ApiClient Configuration Tests', () {
    const testBaseUrl = 'https://example.com/poker';
    const testToken = 'mock_jwt_token';

    test('should configure baseUrl and authorization headers correctly', () {
      final client = ApiClient(baseUrl: testBaseUrl, token: testToken);
      
      expect(client.baseUrl, testBaseUrl);
      expect(client.token, testToken);
    });
  });
}
