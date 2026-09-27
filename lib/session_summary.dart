import 'package:flutter/foundation.dart';

import 'api/api_client.dart';

/// What the wide layout's sidebar needs to know about the signed-in player, wherever they are.
@immutable
class SessionSummaryData {
  const SessionSummaryData({
    this.balanceChips,
    this.isOperator = false,
    this.pendingCount = 0,
  });

  /// The wallet balance in chips, or null until one has actually been fetched. The sidebar shows
  /// a dash for null rather than a zero, which would be a number the player might believe.
  final int? balanceChips;

  /// Whether this player runs the house. Gates the sidebar's "House" group exactly as it gates
  /// the House card on the wallet screen - a player who is not an operator cannot use either
  /// screen behind it, so neither is offered.
  final bool isOperator;

  /// Payouts the house still owes, for the badge on the pending entry. Meaningless, and never
  /// fetched, unless [isOperator].
  final int pendingCount;

  SessionSummaryData copyWith({
    int? balanceChips,
    bool? isOperator,
    int? pendingCount,
  }) => SessionSummaryData(
    balanceChips: balanceChips ?? this.balanceChips,
    isOperator: isOperator ?? this.isOperator,
    pendingCount: pendingCount ?? this.pendingCount,
  );
}

/// A cache of [SessionSummaryData], shared by every screen that draws the sidebar.
///
/// The sidebar is on all nine signed-in wide screens, four of which have no other reason to talk
/// to the wallet or to ask whether this player runs the house. Holding the answers here means
/// arriving at one of those from the lobby draws a filled-in sidebar straight away, and means a
/// screen that fetches the wallet for its own sake publishes that fetch to the sidebar rather
/// than the two drifting apart.
class SessionSummary extends ValueNotifier<SessionSummaryData> {
  SessionSummary._() : super(const SessionSummaryData());

  static final SessionSummary instance = SessionSummary._();

  bool _inFlight = false;

  /// Publishes a balance a screen has just fetched for its own purposes.
  void setBalance(int? chips) => value = SessionSummaryData(
    balanceChips: chips,
    isOperator: value.isOperator,
    pendingCount: value.pendingCount,
  );

  /// Publishes what a screen has just learned about the house.
  void setHouse({required bool isOperator, int? pendingCount}) =>
      value = value.copyWith(
        isOperator: isOperator,
        pendingCount: isOperator ? (pendingCount ?? value.pendingCount) : 0,
      );

  /// Fills in whatever is still unknown. Screens that draw the sidebar call this on arrival, so
  /// a deep link straight onto one of them fills the card in too.
  Future<void> ensure(ApiClient client) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      if (value.balanceChips == null) {
        try {
          setBalance(await client.getWallet());
        } catch (_) {
          // Non-critical: the sidebar keeps its dash, and whatever screen the player is on
          // reports its own failure if it needed the wallet too.
        }
      }
      if (!value.isOperator) {
        try {
          final isOperator = await client.isOperator();
          if (!isOperator) return;
          final pending = await client.listPendingRedemptions();
          setHouse(isOperator: true, pendingCount: pending.length);
        } catch (_) {
          // Leave it false - an unreachable server is not a reason to show house affordances.
        }
      }
    } finally {
      _inFlight = false;
    }
  }

  /// Dropped on sign-out, so the next player to sign in on this device never sees the last one's
  /// balance, or their house access, while their own is being fetched.
  void clear() => value = const SessionSummaryData();
}
