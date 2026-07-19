import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final String token;

  ApiClient({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// POST /games
  /// Create a new game table
  Future<Map<String, dynamic>> createGame(String name, int smallBlind, int bigBlind) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'blinds': {
          'small': smallBlind,
          'big': bigBlind,
        },
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /games/{gameId}
  /// Get game details
  Future<Map<String, dynamic>> getGame(String gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/games/$gameId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /games/{gameId}/players
  /// Register/Buy-in a player to the game
  Future<void> buyIn(String gameId, int buyInAmount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games/$gameId/players'),
      headers: _headers,
      body: jsonEncode({
        'buyInAmount': buyInAmount,
      }),
    );

    if (response.statusCode == 204) {
      return;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /deals/{dealId}/actions
  /// Take a gameplay action
  Future<void> takeAction({
    required String dealId,
    required String actionType,
    int? amount,
    required String timeoutLimit,
  }) async {
    final bodyMap = <String, dynamic>{
      'actionType': actionType,
      'timeoutLimit': timeoutLimit,
    };
    if (amount != null) {
      bodyMap['amount'] = amount;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/deals/$dealId/actions'),
      headers: _headers,
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode == 204) {
      return;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /deals/{dealId}/hand/me
  /// Fetch the calling player's private cards
  Future<Map<String, dynamic>> getMyHand(String dealId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/deals/$dealId/hand/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /games/{gameId}/events
  /// Stream of timeline events (SSE)
  Stream<Map<String, dynamic>> streamEvents(String gameId) async* {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/games/$gameId/events');
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Failed to connect to event stream (Status ${response.statusCode})');
      }

      final lines = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String currentData = '';
      await for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          if (currentData.isNotEmpty) {
            try {
              final decoded = jsonDecode(currentData);
              yield decoded;
            } catch (e) {
              // Ignore malformed JSON
            }
            currentData = '';
          }
          continue;
        }

        if (trimmed.startsWith('data:')) {
          final dataVal = trimmed.substring(5).trim();
          currentData += dataVal;
        } else if (trimmed.startsWith('data :')) {
          final dataVal = trimmed.substring(6).trim();
          currentData += dataVal;
        }
      }
    } catch (e) {
      yield {
        'type': 'ERROR',
        'timestamp': DateTime.now().toIso8601String(),
        'payload': {'message': e.toString()}
      };
    } finally {
      client.close();
    }
  }

  Never _throwDetailedError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'] ?? body['error'] ?? 'Unknown error';
      final code = body['code'] ?? 'HTTP_${response.statusCode}';
      throw ApiException(code: code.toString(), message: message.toString());
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        code: 'HTTP_${response.statusCode}',
        message: response.body.isNotEmpty ? response.body : 'Request failed with status ${response.statusCode}',
      );
    }
  }
}

class ApiException implements Exception {
  final String code;
  final String message;

  ApiException({required this.code, required this.message});

  @override
  String toString() => '$code: $message';
}
