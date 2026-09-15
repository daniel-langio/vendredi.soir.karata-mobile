import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

class MarketplaceScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const MarketplaceScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final ApiClient _apiClient;
  late final TabController _tabController;
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _stands = [];
  bool _isLoading = true;

  /// Who may create a listing, answered by the server (`operator` on GET /poker/account) rather
  /// than by comparing the username to a hardcoded "dev". Selling is server-enforced either way;
  /// this only decides whether the affordance is worth showing. Defaults to false so a failed
  /// lookup hides the button rather than offering one that would 403.
  bool _canSell = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _tabController = TabController(length: 2, vsync: this);
    // The FAB's action follows the visible tab, so it has to rebuild when the tab does.
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _load();
    _loadCanSell();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Both tabs are refreshed together - they share one spinner and one refresh button, and a
  /// player switching tabs shouldn't have to wait for a second round trip.
  Future<void> _load() async {
    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context);
    try {
      final listings = await _apiClient.listMarketplaceListings();
      if (!mounted) return;
      setState(() => _listings = listings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotLoadListings('$e')),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    }
    try {
      final stands = await _apiClient.listRedemptionStands();
      if (!mounted) return;
      setState(() => _stands = stands);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotLoadStands('$e')),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadCanSell() async {
    try {
      final isOperator = await _apiClient.isOperator();
      if (mounted) setState(() => _canSell = isOperator);
    } catch (_) {
      // Leave _canSell false: an unreachable server is not a reason to show a sell button.
    }
  }

  Future<void> _openListing(Map<String, dynamic> listing) async {
    await Navigator.of(context).pushNamed(
      '/marketplace/listing',
      arguments: {
        'serverUrl': widget.serverUrl,
        'token': widget.token,
        'username': widget.username,
        'listing': listing,
      },
    );
    _load();
  }

  Future<void> _cancelListing(Map<String, dynamic> listing) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.cancelListingTitle),
        content: Text(t.cancelListingContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.cancelListingButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _apiClient.cancelListing(listing['id'] as String);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotCancelListing('$e')),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    }
  }

  Future<void> _createListing() async {
    await Navigator.of(context).pushNamed(
      '/marketplace/new',
      arguments: {
        'serverUrl': widget.serverUrl,
        'token': widget.token,
        'username': widget.username,
      },
    );
    _load();
  }

  Future<void> _createStand() async {
    await Navigator.of(context).pushNamed(
      '/marketplace/stand/new',
      arguments: {
        'serverUrl': widget.serverUrl,
        'token': widget.token,
        'username': widget.username,
      },
    );
    _load();
  }

  /// A closed stand has no redeem form to show, so tapping it explains itself instead: who to
  /// contact, and why it's shut.
  void _showStandClosed(Map<String, dynamic> stand) {
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.standClosedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${stand['title']}',
              style: const TextStyle(color: KarataColors.ink, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Text(
              t.standContactLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KarataColors.dim,
              ),
            ),
            const SizedBox(height: 2),
            SelectableText(
              '${stand['contact']}',
              style: const TextStyle(color: KarataColors.ink, fontSize: 14.5),
            ),
            const SizedBox(height: 14),
            Text(
              t.standReasonLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KarataColors.dim,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${stand['closedReason'] ?? ''}',
              style: const TextStyle(
                color: KarataColors.ink,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final canSell = _canSell;
    final onRedeemTab = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: canSell
          ? FloatingActionButton.extended(
              onPressed: onRedeemTab ? _createStand : _createListing,
              icon: const Icon(Icons.add),
              label: Text(onRedeemTab ? t.newStand : t.newListing),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.marketplaceTitle,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w300,
                  color: KarataColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.marketplaceSubtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: KarataColors.dim,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: KarataColors.ink,
                unselectedLabelColor: KarataColors.dim,
                indicatorColor: KarataColors.chipInk,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: const Color(0xFF1A181E),
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: t.tabBuy),
                  Tab(text: t.tabRedeem),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [_buildListings(t), _buildStands(t)],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListings(AppLocalizations t) {
    if (_listings.isEmpty) {
      return Center(
        child: Text(
          t.noListingsYet,
          textAlign: TextAlign.center,
          style: const TextStyle(color: KarataColors.dim),
        ),
      );
    }
    return ListView.separated(
      itemCount: _listings.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFF1A181E)),
      itemBuilder: (context, index) {
        final listing = _listings[index];
        final isMine = listing['sellerUsername'] == widget.username;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.monetization_on_rounded,
            color: KarataColors.chipInk,
          ),
          title: Text(
            t.chipsAvailable('${listing['chipsAmount']}'),
            style: const TextStyle(color: KarataColors.ink, fontSize: 16.5),
          ),
          subtitle: Text(
            t.unitPriceLine(
              '${listing['unitPriceAr']}',
              '${listing['provider']}',
            ),
            style: const TextStyle(color: KarataColors.dim, fontSize: 12.5),
          ),
          trailing: isMine
              ? TextButton(
                  onPressed: () => _cancelListing(listing),
                  child: Text(t.cancelListingButton),
                )
              : TextButton(
                  onPressed: () => _openListing(listing),
                  child: Text(t.buy),
                ),
          onTap: isMine ? null : () => _openListing(listing),
        );
      },
    );
  }

  Widget _buildStands(AppLocalizations t) {
    if (_stands.isEmpty) {
      return Center(
        child: Text(
          t.noStandsYet,
          textAlign: TextAlign.center,
          style: const TextStyle(color: KarataColors.dim),
        ),
      );
    }
    return ListView.separated(
      itemCount: _stands.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFF1A181E)),
      itemBuilder: (context, index) {
        final stand = _stands[index];
        // Every stand is closed until the payout flow exists, so there is no open branch to
        // render yet - an open one would want a redeem form here instead of the dialog.
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.storefront_rounded,
            color: KarataColors.chipInk,
          ),
          title: Text(
            '${stand['title']}',
            style: const TextStyle(color: KarataColors.ink, fontSize: 16.5),
          ),
          subtitle: Text(
            '${stand['provider']}',
            style: const TextStyle(color: KarataColors.dim, fontSize: 12.5),
          ),
          trailing: Text(
            t.standClosed,
            style: const TextStyle(color: KarataColors.dim, fontSize: 12.5),
          ),
          onTap: () => _showStandClosed(stand),
        );
      },
    );
  }
}
