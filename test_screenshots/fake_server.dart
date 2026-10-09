import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Base URL the screenshot run hands every screen. Nothing is ever sent anywhere - [fakeKarata]
/// answers in-process - but the screens build their request paths off it, so it has to look real.
const shotsServerUrl = 'https://shots.karata/poker';

const shotsUsername = 'eli';
const shotsGameId = '7f3c1e5a-4b2d-4c8e-9a10-6d5b2f8e1c44';

/// A second table id, served at showdown rather than mid-flop.
const shotsShowdownGameId = '7f3c1e5a-4b2d-4c8e-9a10-6d5b2f8e1c55';

/// The room the photographed player is already sitting in, and the table it put them at - which
/// is what makes the Gold card in the Rooms tab draw its "Seated" state rather than a buy-in.
const shotsSeatedRoomId = '5a0e9d77-0000-4000-8000-00000000aa01';
const shotsRoomGameId = '7f3c1e5a-4b2d-4c8e-9a10-6d5b2f8e1c66';
const _dealId = 'a1b2c3d4-0000-4000-8000-000000000001';

/// A stand-in for the karata backend, so every screen can be photographed full of plausible data
/// rather than showing the "could not load" state an unreachable server produces. The real
/// binding answers every request with a 400, which is right for the behaviour tests in `test/` -
/// it is exactly wrong for a screenshot a designer is meant to work from.
///
/// Routed on path alone. These are pictures, not assertions: nothing here checks a method, a
/// header or a body, and a path with no fixture answers 404 so the gap shows up in the shot
/// rather than hanging the test.
http.Client fakeKarata() {
  return MockClient((request) async {
    final body = _fixtureFor(request.url.path);
    if (body == null) {
      return http.Response(
        jsonEncode({
          'message': 'no screenshot fixture for ${request.url.path}',
        }),
        404,
        headers: _json,
      );
    }
    return http.Response(jsonEncode(body), 200, headers: _json);
  });
}

const _json = {'content-type': 'application/json; charset=utf-8'};

Object? _fixtureFor(String path) {
  switch (path) {
    case '/poker/wallet':
      return {'chips': 24500};
    case '/poker/account':
      // Operator true so the economy screens photograph with their operator affordances visible -
      // those screens exist and a designer has to see them.
      return {'operator': true, 'phoneNumber': '+261 34 12 345 67'};
    case '/poker/games/mine':
      return _myTables;
    case '/poker/games/public':
      return _publicTables;
    case '/poker/rooms':
      return _rooms;
    case '/poker/admin/rooms':
      return _adminRooms;
    case '/poker/admin/players':
      return _adminPlayers;
    case '/poker/admin/tables':
      return _adminTables;
    case '/economy/price':
      return {
        'arPerChip': 100,
        'sellPricePerChip': 100,
        'depositFeePercent': 10,
        'depositFeeMin': 500,
        'redeemFeePercent': 5,
        'redeemFeeMin': 300,
      };
    case '/economy/config':
      return {
        'houseReceivingPhoneNumber': '+261 34 12 345 67',
        'houseReceivingPhoneNumberMvola': '+261 34 12 345 67',
        'houseReceivingPhoneNumberOrangeMoney': '+261 32 12 345 67',
        'houseReceivingPhoneNumberAirtelMoney': '+261 33 12 345 67',
        'arPerChip': 100,
        'depositFeePercent': 10,
        'depositFeeMin': 500,
        'redeemFeePercent': 5,
        'redeemFeeMin': 300,
        'rakePercent': 5,
        'rakeMin': 40,
        'enforceDepositOnRegistration': true,
      };
    case '/economy/redemptions/pending':
      return _pendingRedemptions;
  }
  if (path.startsWith('/poker/admin/players/')) {
    final username = Uri.decodeComponent(path.split('/').last);
    return _adminPlayerDetail(username);
  }
  if (path.startsWith('/poker/rooms/') && path.endsWith('/stats')) {
    return _roomStats;
  }
  if (path == '/poker/games/$shotsGameId') return gameInPlay();
  if (path == '/poker/games/$shotsShowdownGameId') return gameAtShowdown();
  if (path == '/poker/deals/$_dealId/hand/me') {
    return {
      'cards': ['AS', 'KS'],
    };
  }
  return null;
}

/// Seated players for a lobby row. Named rather than blank, because the V2 table card draws each
/// player as their initial on a coloured disc - blanks would photograph as a row of grey "?"s -
/// and sums their stacks into the balance card's "at tables" figure.
List<Map<String, dynamic>> _seats(List<String> names, {int chips = 180}) => [
  for (final name in names) {'username': name, 'chips': chips},
];

final _myTables = [
  {
    'gameId': shotsGameId,
    'name': 'Vendredi Soir',
    'defaultBuyIn': 200,
    'players': _seats([shotsUsername, 'hanta', 'rivo', 'bot-mika']),
  },
  {
    'gameId': '2c9a7b11-1111-4111-8111-111111111111',
    'name': 'Tsena Kely',
    'defaultBuyIn': 120,
    'players': _seats([shotsUsername, 'naina'], chips: 68),
  },
  {
    'gameId': shotsRoomGameId,
    'name': 'Gold',
    'roomId': shotsSeatedRoomId,
    'defaultBuyIn': 200,
    'players': _seats([shotsUsername, 'tiana', 'rado'], chips: 300),
  },
];

/// The five stake tiers, chosen to cover all four states of a room card in one shot: busy,
/// nobody-here-yet, already-seated and capped-out. Amounts are chips, which the shots render at
/// 100 Ar each.
final _rooms = [
  {
    'roomId': '5a0e9d77-0000-4000-8000-00000000aa00',
    'name': 'Freeroll',
    'blinds': {'small': 1, 'big': 2},
    'defaultBuyIn': 10,
    'variant': 'TEXAS_HOLDEM',
    // The only room whose chips never leave the table, so the "Play chips" tag gets photographed.
    'cashoutEnabled': false,
    'enforceMinimumBuyIn': true,
    'autoRebuyEnabled': false,
    'maxTables': null,
    'tableCount': 2,
    'playerCount': 9,
  },
  {
    'roomId': '5a0e9d77-0000-4000-8000-00000000aa02',
    'name': 'Bronze',
    'blinds': {'small': 5, 'big': 10},
    'defaultBuyIn': 50,
    'variant': 'TEXAS_HOLDEM',
    'cashoutEnabled': true,
    'enforceMinimumBuyIn': true,
    'autoRebuyEnabled': false,
    'maxTables': null,
    'tableCount': 3,
    'playerCount': 14,
  },
  {
    'roomId': '5a0e9d77-0000-4000-8000-00000000aa03',
    'name': 'Silver',
    'blinds': {'small': 10, 'big': 20},
    'defaultBuyIn': 120,
    'variant': 'TEXAS_HOLDEM',
    'cashoutEnabled': true,
    'enforceMinimumBuyIn': true,
    'autoRebuyEnabled': false,
    'maxTables': null,
    // Genuinely empty, and photographed as such: nothing is ever seated to pad the numbers.
    'tableCount': 0,
    'playerCount': 0,
  },
  {
    'roomId': shotsSeatedRoomId,
    'name': 'Gold',
    'blinds': {'small': 25, 'big': 50},
    'defaultBuyIn': 200,
    'variant': 'OMAHA',
    'cashoutEnabled': true,
    'enforceMinimumBuyIn': true,
    'autoRebuyEnabled': false,
    'maxTables': null,
    'tableCount': 1,
    'playerCount': 6,
  },
  {
    'roomId': '5a0e9d77-0000-4000-8000-00000000aa04',
    'name': 'High Roller',
    'blinds': {'small': 100, 'big': 200},
    'defaultBuyIn': 1500,
    'variant': 'TEXAS_HOLDEM',
    'cashoutEnabled': true,
    'enforceMinimumBuyIn': true,
    'autoRebuyEnabled': false,
    // Four tables allowed, four running, every one of the 24 seats taken.
    'maxTables': 4,
    'tableCount': 4,
    'playerCount': 24,
  },
];

final _publicTables = [
  {
    'gameId': '3d8b6c22-2222-4222-8222-222222222222',
    'name': 'Analakely Nights',
    'isPublic': true,
    'defaultBuyIn': 500,
    'players': _seats(['rado', 'tiana', 'naina', 'fara', 'hery']),
  },
  {
    'gameId': '4e7c5d33-3333-4333-8333-333333333333',
    'name': 'Débutants',
    'isPublic': true,
    'defaultBuyIn': 100,
    'players': _seats(['soa', 'hanta', 'fara']),
  },
];

final _pendingRedemptions = [
  {
    'id': '9a1b2c33-4444-4444-8444-444444444444',
    'totalPriceAr': 45000,
    'payoutPhoneNumber': '+261 34 55 123 45',
    'provider': 'MVOLA',
    'pspRef': 'TX8842019',
  },
  {
    'id': '8b2c3d44-5555-4555-8555-555555555555',
    'totalPriceAr': 12000,
    'payoutPhoneNumber': '+261 32 77 998 21',
    'provider': 'ORANGE_MONEY',
    'pspRef': 'OM5530771',
  },
];

/// The admin rooms payload: the same five tiers, spelled flat the way /poker/admin/rooms does,
/// with High Roller closed so the Disabled row and filter both photograph.
final _adminRooms = [
  for (final room in _rooms)
    {
      ...room,
      'smallBlind': (room['blinds']! as Map)['small'],
      'bigBlind': (room['blinds']! as Map)['big'],
      'closed': room['name'] == 'High Roller',
    },
];

/// Accounts covering every state the Players list distinguishes: seated and not, human and bot,
/// active and suspended, and one with no recorded join date.
final _adminPlayers = [
  _adminPlayer(
    shotsUsername,
    balance: 24500,
    joinedAt: '2026-09-12T09:14:00Z',
    atTable: 'Analakely Nights',
  ),
  _adminPlayer(
    'daniel_langio',
    balance: 6100,
    joinedAt: '2025-07-03T11:02:00Z',
  ),
  _adminPlayer(
    'hanta',
    balance: 96,
    joinedAt: '2026-09-19T18:40:00Z',
    atTable: 'Vendredi Soir',
  ),
  _adminPlayer(
    'rivo',
    balance: 0,
    joinedAt: '2026-09-19T18:41:00Z',
    atTable: 'Vendredi Soir',
  ),
  _adminPlayer(
    'anishmujumdar150',
    balance: 4100,
    joinedAt: '2026-02-02T08:00:00Z',
    suspended: true,
  ),
  // No joinedAt: an account from before the column existed, which the list prints as a dash
  // rather than back-dating.
  _adminPlayer('polskipoker', balance: 4610),
  _adminPlayer(
    'bot-mika-01',
    balance: 240,
    bot: true,
    atTable: 'Vendredi Soir',
  ),
  _adminPlayer('bot-noro-04', balance: 184, bot: true),
];

Map<String, dynamic> _adminPlayer(
  String username, {
  required int balance,
  String? joinedAt,
  String? atTable,
  bool bot = false,
  bool suspended = false,
}) => {
  'username': username,
  'bot': bot,
  'suspended': suspended,
  'joinedAt': joinedAt,
  'balance': balance,
  'atTableId': atTable == null ? null : shotsGameId,
  'atTableName': atTable,
};

Map<String, dynamic> _adminPlayerDetail(String username) {
  final player = _adminPlayers.firstWhere(
    (p) => p['username'] == username,
    orElse: () => _adminPlayers.first,
  );
  return {
    'player': player,
    'phoneNumber': '+261 34 12 345 67',
    'lifetimeDeposited': 31000,
    'lifetimeWithdrawn': 6500,
  };
}

/// Tables covering open, full, paused and a room's own table.
final _adminTables = [
  _adminTable('Analakely Nights', seated: 5, isPublic: true, buyIn: 500),
  _adminTable('Vendredi Soir', seated: 2, status: 'OPEN', buyIn: null),
  _adminTable('Débutants', seated: 3, isPublic: true, buyIn: 100),
  _adminTable('Neon Deal', seated: 1, status: 'PAUSED', buyIn: 200),
  _adminTable(
    'High Rollers',
    seated: 6,
    status: 'FULL',
    isPublic: true,
    buyIn: 2000,
  ),
  _adminTable('Bronze', seated: 5, buyIn: 50, roomName: 'Bronze'),
];

Map<String, dynamic> _adminTable(
  String name, {
  required int seated,
  required int? buyIn,
  String status = 'OPEN',
  bool isPublic = false,
  String? roomName,
}) => {
  'gameId': shotsGameId,
  'name': name,
  'isPublic': isPublic,
  'status': status,
  'seated': seated,
  'capacity': 6,
  'smallBlind': 1,
  'bigBlind': 2,
  'defaultBuyIn': buyIn,
  'variant': 'TEXAS_HOLDEM',
  'roomId': roomName == null ? null : shotsSeatedRoomId,
  'roomName': roomName,
  'host': shotsUsername,
  'createdAt': '2026-09-27T18:04:11Z',
};

/// The per-table breakdown the room editor lists, spare included.
final _roomStats = {
  'roomId': shotsSeatedRoomId,
  'name': 'Bronze',
  'closed': false,
  'liveTables': 4,
  'occupiedTables': 3,
  'seatedPlayers': 14,
  'freeSeats': 10,
  'dormantTables': 1,
  'tables': [
    {
      'gameId': shotsGameId,
      'name': 'Bronze #1',
      'seated': 5,
      'freeSeats': 1,
      'spare': false,
      'paused': false,
      'createdAt': '2026-09-27T18:04:11Z',
    },
    {
      'gameId': shotsRoomGameId,
      'name': 'Bronze #2',
      'seated': 5,
      'freeSeats': 1,
      'spare': false,
      'paused': false,
      'createdAt': '2026-09-27T18:40:02Z',
    },
    {
      'gameId': shotsShowdownGameId,
      'name': 'Bronze #3',
      'seated': 0,
      'freeSeats': 6,
      'spare': true,
      'paused': false,
      'createdAt': '2026-09-27T19:21:02Z',
    },
  ],
};

/// A hand mid-flop with the photographed player on the clock, because that is the state the table
/// has the most to show: community cards down, a live pot, a dealer button, someone all in, and
/// the action buttons enabled rather than greyed.
Map<String, dynamic> gameInPlay() => {
  'gameId': shotsGameId,
  'name': 'Vendredi Soir',
  'variant': 'TEXAS_HOLDEM',
  'defaultBuyIn': 200,
  'initiatorUsername': shotsUsername,
  'isPublic': false,
  'paused': false,
  'closed': false,
  'blinds': {'small': 1, 'big': 2},
  'currentDealId': _dealId,
  'you': {'callAmount': 12, 'minRaise': 24, 'maxRaise': 188, 'dealer': false},
  'players': [
    {
      'playerId': 'p1',
      'username': shotsUsername,
      'chips': 188,
      'status': 'ACTIVE',
      'contributionThisRound': 0,
      'dealer': false,
      'isBot': false,
      'blind': null,
      'lastAction': null,
    },
    {
      'playerId': 'p2',
      'username': 'hanta',
      'chips': 96,
      'status': 'ACTIVE',
      'contributionThisRound': 12,
      'dealer': true,
      'isBot': false,
      'blind': 'SMALL',
      'lastAction': 'BET 12',
    },
    {
      'playerId': 'p3',
      'username': 'rivo',
      'chips': 0,
      'status': 'ALL_IN',
      'contributionThisRound': 74,
      'dealer': false,
      'isBot': false,
      'blind': 'BIG',
      'lastAction': 'RAISE 74',
    },
    {
      'playerId': 'p4',
      'username': 'bot-mika',
      'chips': 240,
      'status': 'FOLDED',
      'contributionThisRound': 0,
      'dealer': false,
      'isBot': true,
      'blind': null,
      'lastAction': 'FOLD 0',
    },
  ],
  'currentDeal': {
    'phase': 'FLOP',
    'pot': 86,
    'currentRoundBet': 12,
    'activePlayerId': 'p1',
    'communityCards': ['AS', 'TD', '7C', null, null],
    // Far enough out that the countdown reads as a comfortable number rather than a red warning,
    // and fixed relative to now so the shot is the same whenever it is taken.
    'turnDeadline': DateTime.now()
        .toUtc()
        .add(const Duration(seconds: 18))
        .toIso8601String(),
    'outcome': null,
  },
};

/// The same table at showdown: the board complete, two hands turned over, and a winner named.
///
/// Photographed as its own screen because a showdown exercises parts of the table nothing else
/// reaches - revealed opponent hands, the winning-card highlight, the outcome banner - and those
/// are exactly the parts that can break without any other shot noticing.
Map<String, dynamic> gameAtShowdown() {
  final game = gameInPlay();
  final deal = Map<String, dynamic>.from(
    game['currentDeal'] as Map<String, dynamic>,
  );
  deal['phase'] = 'SHOWDOWN';
  deal['activePlayerId'] = null;
  deal['communityCards'] = ['AS', 'TD', '7C', 'AH', '2C'];
  deal['pot'] = 246;
  deal['outcome'] = {
    'winners': [
      {'username': shotsUsername, 'amount': 246, 'handRank': 'Pair of aces'},
    ],
    'revealedHands': [
      {
        'playerId': 'p1',
        'username': shotsUsername,
        'holeCards': ['AC', 'KS'],
        'handRank': 'Pair of aces',
        'winner': true,
      },
      {
        'playerId': 'p2',
        'username': 'hanta',
        'holeCards': ['QD', 'JH'],
        'handRank': 'Ace high',
        'winner': false,
      },
    ],
    'winningCards': ['AS', 'AH', 'AC'],
  };
  game['currentDeal'] = deal;
  return game;
}
