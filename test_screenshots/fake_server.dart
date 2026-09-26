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
    case '/economy/price':
      return {'arPerChip': 100, 'sellPricePerChip': 110};
    case '/economy/config':
      return {
        'houseReceivingPhoneNumber': '+261 34 12 345 67',
        'arPerChip': 100,
        'sellSpreadPercent': 10,
        'rakePercent': 5,
        'rakeMinPot': 40,
      };
    case '/economy/redemptions/pending':
      return _pendingRedemptions;
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
];

final _publicTables = [
  {
    'gameId': '3d8b6c22-2222-4222-8222-222222222222',
    'name': 'Analakely Nights',
    'defaultBuyIn': 500,
    'players': _seats(['rado', 'tiana', 'naina', 'fara', 'hery']),
  },
  {
    'gameId': '4e7c5d33-3333-4333-8333-333333333333',
    'name': 'Débutants',
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
