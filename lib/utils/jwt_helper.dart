import 'dart:convert';

class JwtHelper {
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }
      final payloadPart = parts[1];
      String normalized = base64Url.normalize(payloadPart);
      final decodedString = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static String? getPlayerId(String token) {
    final payload = decode(token);
    if (payload == null) return null;
    return payload['playerId']?.toString() ??
           payload['userId']?.toString() ??
           payload['sub']?.toString() ??
           payload['id']?.toString();
  }

  static String? getUsername(String token) {
    final payload = decode(token);
    if (payload == null) return null;
    return payload['username']?.toString() ??
           payload['name']?.toString() ??
           payload['preferred_username']?.toString() ??
           payload['sub']?.toString();
  }
}
