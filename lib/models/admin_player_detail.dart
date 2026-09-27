import 'admin_player.dart';

/// One account with the figures the list does not carry - what the edit screen shows.
///
/// Both lifetime totals count only transactions that actually cleared, so they are what moved
/// rather than what was attempted.
class AdminPlayerDetail {
  final AdminPlayer player;
  final String? phoneNumber;
  final int lifetimeDeposited;
  final int lifetimeWithdrawn;

  const AdminPlayerDetail({
    required this.player,
    required this.phoneNumber,
    required this.lifetimeDeposited,
    required this.lifetimeWithdrawn,
  });

  factory AdminPlayerDetail.fromJson(Map<String, dynamic> j) =>
      AdminPlayerDetail(
        player: AdminPlayer.fromJson(
          j['player'] as Map<String, dynamic>? ?? const {},
        ),
        phoneNumber: j['phoneNumber'] as String?,
        lifetimeDeposited: (j['lifetimeDeposited'] as num?)?.toInt() ?? 0,
        lifetimeWithdrawn: (j['lifetimeWithdrawn'] as num?)?.toInt() ?? 0,
      );
}
