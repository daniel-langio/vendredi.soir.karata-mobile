/// One live table as only an operator sees it - other players' private tables included.
///
/// No pot: knowing one means replaying a deal, so a list of tables would replay every game on
/// every refresh. The server deliberately does not offer it.
class AdminTable {
  final String gameId;
  final String name;
  final bool isPublic;

  /// `OPEN` | `FULL` | `PAUSED` | `DORMANT`.
  final String status;

  final int seated;
  final int capacity;
  final int? smallBlind;
  final int? bigBlind;
  final int? defaultBuyIn;
  final String? variant;

  /// The room that opened this table, or null for a player-hosted or public one.
  final String? roomId;
  final String? roomName;

  final String? host;
  final DateTime? createdAt;

  const AdminTable({
    required this.gameId,
    required this.name,
    required this.isPublic,
    required this.status,
    required this.seated,
    required this.capacity,
    required this.smallBlind,
    required this.bigBlind,
    required this.defaultBuyIn,
    required this.variant,
    required this.roomId,
    required this.roomName,
    required this.host,
    required this.createdAt,
  });

  bool get paused => status == 'PAUSED';

  /// A room's table is reached by sitting down in the room, never by being listed on its own, so
  /// the public toggle is not the operator's to move.
  bool get belongsToRoom => roomId != null;

  factory AdminTable.fromJson(Map<String, dynamic> j) => AdminTable(
    gameId: j['gameId'] as String,
    name: j['name'] as String? ?? 'Table',
    isPublic: j['isPublic'] == true,
    status: j['status'] as String? ?? 'OPEN',
    seated: (j['seated'] as num?)?.toInt() ?? 0,
    capacity: (j['capacity'] as num?)?.toInt() ?? 0,
    smallBlind: (j['smallBlind'] as num?)?.toInt(),
    bigBlind: (j['bigBlind'] as num?)?.toInt(),
    defaultBuyIn: (j['defaultBuyIn'] as num?)?.toInt(),
    variant: j['variant'] as String?,
    roomId: j['roomId'] as String?,
    roomName: j['roomName'] as String?,
    host: j['host'] as String?,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
  );
}
