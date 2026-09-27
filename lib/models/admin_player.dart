/// One account, as the admin Players list shows it.
class AdminPlayer {
  final String username;
  final bool bot;
  final bool suspended;

  /// Null for accounts that registered before the date was recorded - the server does not know,
  /// and the list prints a dash rather than inventing one.
  final DateTime? joinedAt;

  final int balance;

  /// The live table they are sitting at, or null if they are not sitting anywhere.
  final String? atTableId;
  final String? atTableName;

  const AdminPlayer({
    required this.username,
    required this.bot,
    required this.suspended,
    required this.joinedAt,
    required this.balance,
    required this.atTableId,
    required this.atTableName,
  });

  bool get seated => atTableId != null;

  factory AdminPlayer.fromJson(Map<String, dynamic> j) => AdminPlayer(
    username: j['username'] as String? ?? '',
    bot: j['bot'] == true,
    suspended: j['suspended'] == true,
    joinedAt: DateTime.tryParse(j['joinedAt'] as String? ?? ''),
    balance: (j['balance'] as num?)?.toInt() ?? 0,
    atTableId: j['atTableId'] as String?,
    atTableName: j['atTableName'] as String?,
  );
}
