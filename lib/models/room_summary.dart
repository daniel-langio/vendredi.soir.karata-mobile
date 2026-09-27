/// One stake tier in the lobby's Rooms tab.
///
/// A room is not a table. The player picks a tier and the server seats them at the fullest table
/// with a free seat, so nothing here names a table and no endpoint would return one - see
/// `GET /poker/rooms`.
///
/// [tableCount] counts only tables that have someone at them, which is what lets a quiet room
/// read as an honest `0 tables / 0 players` rather than "one table, nobody there": the empty
/// table a room always keeps in reserve is not advertised, and no bot is ever seated to make the
/// room look busier than it is.
class RoomSummary {
  final String roomId;
  final String name;
  final int smallBlind;
  final int bigBlind;
  final int defaultBuyIn;

  /// `TEXAS_HOLDEM` | `OMAHA` | `FIVE_CARD_DRAW`.
  final String variant;

  /// Whether chips won here convert back to Ariary, as opposed to being play money.
  final bool cashoutEnabled;

  /// Whether the server rejects a buy-in below [defaultBuyIn].
  final bool enforceMinimumBuyIn;

  final bool autoRebuyEnabled;

  /// Null when the room may open as many tables as it needs, which is the normal case.
  final int? maxTables;

  final int tableCount;
  final int playerCount;

  const RoomSummary({
    required this.roomId,
    required this.name,
    required this.smallBlind,
    required this.bigBlind,
    required this.defaultBuyIn,
    required this.variant,
    required this.cashoutEnabled,
    required this.enforceMinimumBuyIn,
    required this.autoRebuyEnabled,
    required this.maxTables,
    required this.tableCount,
    required this.playerCount,
  });

  /// Seats at one table, fixed server-side.
  static const seatsPerTable = 6;

  /// No table of this room has anyone at it yet.
  bool get quiet => tableCount == 0;

  /// The smallest buy-in the server would accept. An unenforced room takes any positive amount.
  int get minimumBuyIn => enforceMinimumBuyIn ? defaultBuyIn : 1;

  /// Whether sitting down would be refused for want of anywhere to put the player.
  ///
  /// Only a capped room can reach this, and only once every seat of every table it is allowed to
  /// open is taken - a capped room whose tables are merely all in use still has seats, and the
  /// server will use them. The test errs towards "sittable" on purpose: a room wrongly greyed out
  /// is a dead end the player cannot argue with, whereas wrong optimism ends in the server's own
  /// `409 Room is full` and a message that says so.
  bool get isFull =>
      maxTables != null &&
      tableCount >= maxTables! &&
      playerCount >= maxTables! * seatsPerTable;

  factory RoomSummary.fromJson(Map<String, dynamic> j) {
    final blinds = j['blinds'] as Map<String, dynamic>? ?? const {};
    return RoomSummary(
      roomId: j['roomId'] as String,
      name: j['name'] as String? ?? 'Room',
      smallBlind: (blinds['small'] as num?)?.toInt() ?? 0,
      bigBlind: (blinds['big'] as num?)?.toInt() ?? 0,
      defaultBuyIn: (j['defaultBuyIn'] as num?)?.toInt() ?? 0,
      variant: j['variant'] as String? ?? 'TEXAS_HOLDEM',
      cashoutEnabled: j['cashoutEnabled'] != false,
      enforceMinimumBuyIn: j['enforceMinimumBuyIn'] != false,
      autoRebuyEnabled: j['autoRebuyEnabled'] == true,
      maxTables: (j['maxTables'] as num?)?.toInt(),
      tableCount: (j['tableCount'] as num?)?.toInt() ?? 0,
      playerCount: (j['playerCount'] as num?)?.toInt() ?? 0,
    );
  }
}
