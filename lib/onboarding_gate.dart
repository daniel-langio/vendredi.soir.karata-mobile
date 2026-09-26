import 'api/api_client.dart';

/// Whether this player has to fund their wallet before they can go anywhere else.
///
/// Two conditions, in the cheap-to-check order: the house has turned enforcement on, and the
/// player's wallet is still empty. A player who deposited once is never asked again, however the
/// flag is set afterwards.
///
/// Fails open. A server that cannot answer must not lock anyone out of a game they already paid
/// to sit at - the gate exists to route new players to the till, not to hold the app hostage to a
/// config fetch.
Future<bool> mustDepositFirst(ApiClient client) async {
  try {
    final config = await client.getEconomyConfig();
    if (config['enforceDepositOnRegistration'] != true) return false;
    return await client.getWallet() <= 0;
  } catch (_) {
    return false;
  }
}
