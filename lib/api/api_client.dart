import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final String token;

  ApiClient({required this.baseUrl, this.token = ''});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  /// POST /auth/register
  /// promoCode, when given, is applied atomically with registration server-side - an invalid,
  /// expired, already-used, or exhausted code fails the whole registration rather than silently
  /// skipping the bonus.
  Future<String> register(
    String username,
    String password, {
    String? promoCode,
  }) async {
    final body = <String, dynamic>{'username': username, 'password': password};
    if (promoCode != null && promoCode.isNotEmpty) {
      body['promoCode'] = promoCode;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['token']
          as String;
    }
    _throwDetailedError(response);
  }

  /// POST /auth/login
  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['token']
          as String;
    }
    _throwDetailedError(response);
  }

  /// POST /games
  /// Create a new game table. defaultBuyIn (if given) is kept by the server as the table's
  /// suggested buy-in for anyone joining later - see JoinTableScreen.
  Future<Map<String, dynamic>> createGame(
    String name,
    int smallBlind,
    int bigBlind, {
    int? defaultBuyIn,
    String? variant,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'blinds': {'small': smallBlind, 'big': bigBlind},
    };
    if (defaultBuyIn != null) body['defaultBuyIn'] = defaultBuyIn;
    if (variant != null) body['variant'] = variant;

    final response = await http.post(
      Uri.parse('$baseUrl/games'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /games/{gameId}
  /// Get game details. Sends the auth token when available so the response
  /// includes the personalized "you" betting context.
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
      body: jsonEncode({'buyInAmount': buyInAmount}),
    );

    if (response.statusCode == 204) {
      return;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /games/{gameId}/deals
  /// Start a new hand: the server automatically posts blinds and deals hole cards.
  Future<Map<String, dynamic>> startDeal(String gameId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games/$gameId/deals'),
      headers: _headers,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
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
    List<String>? discard,
  }) async {
    final bodyMap = <String, dynamic>{'actionType': actionType};
    if (amount != null) {
      bodyMap['amount'] = amount;
    }
    if (discard != null) {
      bodyMap['discard'] = discard;
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

  /// POST /games/{gameId}/close
  /// Ends the table for good: no further joins, deals, or actions afterwards.
  Future<void> closeTable(String gameId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games/$gameId/close'),
      headers: _headers,
    );

    if (response.statusCode == 204) {
      return;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /games/public
  /// Operator-only (see GET /account -> operator). The table is hosted by the house rather than
  /// by the caller, and unlike an ordinary table a buy-in tier is required.
  Future<Map<String, dynamic>> createPublicGame(
    String name,
    int smallBlind,
    int bigBlind, {
    required int defaultBuyIn,
    String? variant,
    bool? cashoutEnabled,
    bool? enforceMinimumBuyIn,
    bool? autoRebuyEnabled,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'blinds': {'small': smallBlind, 'big': bigBlind},
      'defaultBuyIn': defaultBuyIn,
    };
    if (variant != null) body['variant'] = variant;
    if (cashoutEnabled != null) body['cashoutEnabled'] = cashoutEnabled;
    if (enforceMinimumBuyIn != null) {
      body['enforceMinimumBuyIn'] = enforceMinimumBuyIn;
    }
    if (autoRebuyEnabled != null) body['autoRebuyEnabled'] = autoRebuyEnabled;

    final response = await http.post(
      Uri.parse('$baseUrl/games/public'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /games/public
  /// The house lobbies listed on the home screen. Seeded server-side and never closable, so this
  /// list is stable - what changes is how many players each one reports.
  Future<List<Map<String, dynamic>>> listPublicTables() async {
    final response = await http.get(
      Uri.parse('$baseUrl/games/public'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /games/mine
  /// Every open table the caller hosts or is still seated at - server-side, so it survives a
  /// reinstall or a change of device.
  Future<List<Map<String, dynamic>>> listMyTables() async {
    final response = await http.get(
      Uri.parse('$baseUrl/games/mine'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /games/{gameId}/pause
  /// Host-only. A paused table rejects deals and actions until it is resumed.
  Future<void> pauseTable(String gameId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games/$gameId/pause'),
      headers: _headers,
    );

    if (response.statusCode == 204) {
      return;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /games/{gameId}/resume
  /// Host-only. Lifts the pause set by [pauseTable].
  Future<void> resumeTable(String gameId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games/$gameId/resume'),
      headers: _headers,
    );

    if (response.statusCode == 204) {
      return;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /games/{gameId}/leave
  /// Stands the caller up from the table for good - excluded from future deals, and folded out of
  /// whichever hand is in progress if they were dealt into it.
  Future<void> leaveTable(String gameId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games/$gameId/leave'),
      headers: _headers,
    );

    if (response.statusCode == 204) {
      return;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /games/{gameId}/bots
  /// Host-only. strategy is one of CAUTIOUS/AGGRESSIVE/BALANCED, or null to let the server pick.
  Future<void> addBot(String gameId, {String? strategy}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/games/$gameId/bots'),
      headers: _headers,
      body: strategy != null ? jsonEncode({'strategy': strategy}) : null,
    );
    if (response.statusCode != 204) {
      _throwDetailedError(response);
    }
  }

  /// GET /wallet
  /// Fetch the caller's persistent chip wallet balance (separate from any single table's
  /// in-progress stack).
  Future<int> getWallet() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['chips'] as num).toInt();
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

  /// GET /account
  /// The account's stored phone number, if any - purely a form-default convenience, never
  /// authoritative (the number that matters for matching is whatever's entered on a given
  /// purchase/redemption).
  /// GET /account -> operator
  /// Whether this account acts as the house: may open public tables and move the global chip
  /// price/economy config. Asked of the server rather than inferred from the username, so the
  /// privileged name lives in one place.
  Future<bool> isOperator() async {
    final response = await http.get(
      Uri.parse('$baseUrl/account'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['operator'] == true;
    } else {
      _throwDetailedError(response);
    }
  }

  Future<String?> getAccountPhoneNumber() async {
    final response = await http.get(
      Uri.parse('$baseUrl/account'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['phoneNumber'] as String?;
    } else {
      _throwDetailedError(response);
    }
  }

  /// PUT /account/phone-number
  Future<void> setAccountPhoneNumber(String phoneNumber) async {
    final response = await http.put(
      Uri.parse('$baseUrl/account/phone-number'),
      headers: _headers,
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );
    if (response.statusCode != 200) {
      _throwDetailedError(response);
    }
  }

  // The economy endpoints live at the API root (sibling to /poker), not under it - baseUrl
  // already has /poker baked in (see WelcomeScreen.defaultServerUrl), so strip it back off here.
  String get _rootUrl => baseUrl.endsWith('/poker')
      ? baseUrl.substring(0, baseUrl.length - '/poker'.length)
      : baseUrl;

  /// GET /economy/price
  /// {arPerChip, sellPricePerChip, effectiveAt} - arPerChip is what redeem pays per chip,
  /// sellPricePerChip (already marked up by the spread) is what a purchase costs per chip.
  Future<Map<String, dynamic>> getChipPrice() async {
    final response = await http.get(
      Uri.parse('$_rootUrl/economy/price'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /economy/price
  /// Operator-only.
  Future<Map<String, dynamic>> setChipPrice(int arPerChip) async {
    final response = await http.post(
      Uri.parse('$_rootUrl/economy/price'),
      headers: _headers,
      body: jsonEncode({'arPerChip': arPerChip}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /economy/config
  Future<Map<String, dynamic>> getEconomyConfig() async {
    final response = await http.get(
      Uri.parse('$_rootUrl/economy/config'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /economy/config
  /// Operator-only. Every field is required - this appends a whole new config row, not a partial
  /// patch of the current one.
  Future<Map<String, dynamic>> setEconomyConfig({
    required int sellSpreadPercent,
    required int rakePercent,
    required int rakeMin,
    required String houseReceivingPhoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$_rootUrl/economy/config'),
      headers: _headers,
      body: jsonEncode({
        'sellSpreadPercent': sellSpreadPercent,
        'rakePercent': rakePercent,
        'rakeMin': rakeMin,
        'houseReceivingPhoneNumber': houseReceivingPhoneNumber,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /economy/purchases
  /// Mints chips once ifay verifies the payment - returns the created purchase, poll it via
  /// getChipPurchase.
  Future<Map<String, dynamic>> buyChips({
    required int quantity,
    required String buyerPhoneNumber,
    required String provider,
    required String pspRef,
  }) async {
    final response = await http.post(
      Uri.parse('$_rootUrl/economy/purchases'),
      headers: _headers,
      body: jsonEncode({
        'quantity': quantity,
        'buyerPhoneNumber': buyerPhoneNumber,
        'provider': provider,
        'pspRef': pspRef,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /economy/purchases/{id}
  /// Re-checks payment status server-side as a side effect - poll this while waiting for a
  /// purchase to verify.
  Future<Map<String, dynamic>> getChipPurchase(String id) async {
    final response = await http.get(
      Uri.parse('$_rootUrl/economy/purchases/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// POST /economy/redemptions
  /// Burns the chips immediately (escrow) and registers the payout intent with ifay - returns the
  /// created redemption, poll it via getChipRedemption.
  Future<Map<String, dynamic>> redeemChips({
    required int quantity,
    required String payoutPhoneNumber,
    required String provider,
  }) async {
    final response = await http.post(
      Uri.parse('$_rootUrl/economy/redemptions'),
      headers: _headers,
      body: jsonEncode({
        'quantity': quantity,
        'payoutPhoneNumber': payoutPhoneNumber,
        'provider': provider,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /economy/redemptions/{id}
  /// Re-checks payout status server-side as a side effect - poll this while waiting for it.
  Future<Map<String, dynamic>> getChipRedemption(String id) async {
    final response = await http.get(
      Uri.parse('$_rootUrl/economy/redemptions/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
    }
  }

  /// GET /economy/redemptions/pending
  /// Operator-only: every redemption still waiting on a manual payout - phone, amount, provider
  /// and the pspRef to quote when sending it.
  Future<List<Map<String, dynamic>>> listPendingRedemptions() async {
    final response = await http.get(
      Uri.parse('$_rootUrl/economy/redemptions/pending'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    } else {
      _throwDetailedError(response);
    }
  }

  /// DELETE /economy/redemptions/{id}
  /// Operator-only: refunds the escrowed chips for a payout that never got confirmed.
  Future<Map<String, dynamic>> cancelRedemption(String id) async {
    final response = await http.delete(
      Uri.parse('$_rootUrl/economy/redemptions/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _throwDetailedError(response);
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
        message: response.body.isNotEmpty
            ? response.body
            : 'Request failed with status ${response.statusCode}',
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
