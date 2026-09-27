/// A seated player, as a lobby list reports them.
typedef SeatedPlayer = ({String name, int chips});

/// One row in either lobby list.
///
/// Both `/games/mine` and `/games/public` return the full game representation, which already
/// carries the seated players and their stacks - so the avatars, the player count and the
/// "at tables" figure on the balance card all cost no extra field on the API and no second
/// request.
class TableSummary {
  final String gameId;
  final String name;
  final int? defaultBuyIn;

  /// The room this table belongs to, or null for a player-hosted or public table. The Rooms tab
  /// matches it against the room it is about to open, so a player who is already sitting there is
  /// sent straight back to their seat instead of being asked to buy in again.
  final String? roomId;

  /// Whether the house hosts this table and anyone may sit down, as opposed to one of your own.
  final bool isPublic;

  /// The seated players, in seat order. The lobby shows the first few as avatars.
  final List<SeatedPlayer> players;

  const TableSummary({
    required this.gameId,
    required this.name,
    required this.defaultBuyIn,
    required this.players,
    this.roomId,
    this.isPublic = false,
  });

  int get seated => players.length;

  List<String> get playerNames => [for (final p in players) p.name];

  /// What [username] has in front of them at this table, or null if they are not seated here.
  int? stackOf(String username) {
    for (final p in players) {
      if (p.name == username) return p.chips;
    }
    return null;
  }

  factory TableSummary.fromJson(Map<String, dynamic> j) => TableSummary(
    gameId: j['gameId'] as String,
    name: j['name'] as String? ?? 'Table',
    defaultBuyIn: (j['defaultBuyIn'] as num?)?.toInt(),
    roomId: j['roomId'] as String?,
    isPublic: j['isPublic'] == true,
    players: [
      for (final p in (j['players'] as List<dynamic>? ?? const []))
        (
          name: (p as Map<String, dynamic>)['username'] as String? ?? '',
          chips: (p['chips'] as num?)?.toInt() ?? 0,
        ),
    ],
  );
}
