import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../table_name_generator.dart';
import '../theme.dart';

class NewTableScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const NewTableScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends State<NewTableScreen> {
  final _nameController = TextEditingController(text: generateTableName());
  // Blinds and buy-in are asked for in whatever unit the player reads the rest of the app in, so
  // the defaults are seeded through the same conversion the entries are read back with.
  final _display = ChipDisplay.instance.value;
  late final _smallBlindController = TextEditingController(
    text: '${_display.entryFromChips(1)}',
  );
  late final _bigBlindController = TextEditingController(
    text: '${_display.entryFromChips(2)}',
  );
  late final _buyInController = TextEditingController(
    text: '${_display.entryFromChips(200)}',
  );
  String _variant = 'TEXAS_HOLDEM';
  bool _isLoading = false;
  bool _isOperator = false;
  bool _makePublic = false;
  bool _cashoutEnabled = true;
  bool _enforceMinimumBuyIn = true;
  bool _autoRebuyEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkOperator();
  }

  /// Whether to offer the public-table switch is the server's answer, not a username the client
  /// recognises - a player who flipped it anyway would just be refused by POST /games/public.
  Future<void> _checkOperator() async {
    try {
      final isOperator = await ApiClient(
        baseUrl: widget.serverUrl,
        token: widget.token,
      ).isOperator();
      if (!mounted) return;
      setState(() => _isOperator = isOperator);
    } catch (_) {
      // Non-critical - the switch just stays hidden if we can't reach the server.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _smallBlindController.dispose();
    _bigBlindController.dispose();
    _buyInController.dispose();
    super.dispose();
  }

  /// Reads one amount field as chips. Null (rather than zero) for anything unparseable, so the
  /// "fill in valid values" guard below still catches an empty or junk entry.
  int? _chipsFrom(TextEditingController controller) {
    final entered = int.tryParse(controller.text.trim());
    return entered == null ? null : _display.chipsFromEntry(entered);
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    // The API only ever speaks chips, whatever unit the fields were filled in.
    final sb = _chipsFrom(_smallBlindController);
    final bb = _chipsFrom(_bigBlindController);
    final buyIn = _chipsFrom(_buyInController);

    if (name.isEmpty ||
        sb == null ||
        sb <= 0 ||
        bb == null ||
        bb <= 0 ||
        buyIn == null ||
        buyIn <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).fillValidValues),
          backgroundColor: KarataColors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
      final publicTable = _isOperator && _makePublic;
      final game = publicTable
          ? await client.createPublicGame(
              name,
              sb,
              bb,
              defaultBuyIn: buyIn,
              variant: _variant,
              cashoutEnabled: _cashoutEnabled,
              enforceMinimumBuyIn: _enforceMinimumBuyIn,
              autoRebuyEnabled: _autoRebuyEnabled,
            )
          : await client.createGame(
              name,
              sb,
              bb,
              defaultBuyIn: buyIn,
              variant: _variant,
            );
      final gameId = game['gameId'] as String;
      // A public table is the house's and the operator is not one of its players, so the buy-in
      // here is the tier everyone else will pay rather than a seat being taken.
      if (!publicTable) {
        await client.buyIn(gameId, buyIn);
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/table/$gameId',
          arguments: {
            'serverUrl': widget.serverUrl,
            'token': widget.token,
            'username': widget.username,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).couldNotCreateTable('$e'),
            ),
            backgroundColor: KarataColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              t.newTableTitle,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w300,
                color: KarataColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.newTableSubtitle,
              style: const TextStyle(
                fontSize: 13.5,
                color: KarataColors.dim,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: KarataColors.ink),
                    decoration: InputDecoration(labelText: t.name),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  tooltip: t.generateTableName,
                  onPressed: () => setState(
                    () => _nameController.text = generateTableName(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _variant,
              dropdownColor: KarataColors.field,
              style: const TextStyle(color: KarataColors.ink),
              decoration: InputDecoration(labelText: t.gameVariant),
              items: [
                DropdownMenuItem(
                  value: 'TEXAS_HOLDEM',
                  child: Text(t.variantTexasHoldemShort),
                ),
                DropdownMenuItem(
                  value: 'OMAHA',
                  child: Text(t.variantOmahaShort),
                ),
                DropdownMenuItem(
                  value: 'FIVE_CARD_DRAW',
                  child: Text(t.variantFiveCardDrawShort),
                ),
                DropdownMenuItem(
                  value: 'SEVEN_CARD_STUD',
                  child: Text(
                    '${t.variantSevenCardStudShort} (${t.comingSoon})',
                    style: const TextStyle(color: KarataColors.dim),
                  ),
                ),
              ],
              // SEVEN_CARD_STUD is shown (dimmed) but not selectable yet - DropdownMenuItem has
              // no per-item `enabled` flag, so this rejects the pick and leaves _variant as-is.
              onChanged: (value) {
                if (value == 'SEVEN_CARD_STUD') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${t.variantSevenCardStudShort} - ${t.comingSoon}',
                      ),
                      backgroundColor: KarataColors.pill,
                    ),
                  );
                  return;
                }
                setState(() => _variant = value ?? _variant);
              },
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _smallBlindController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: KarataColors.ink),
                    decoration: InputDecoration(labelText: t.smallBlind),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: TextField(
                    controller: _bigBlindController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: KarataColors.ink),
                    decoration: InputDecoration(labelText: t.bigBlind),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              t.yourBuyIn,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KarataColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _buyInController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: KarataColors.ink),
              decoration: InputDecoration(labelText: t.amount),
            ),
            if (_isOperator) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _makePublic,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _makePublic = value),
                title: Text(
                  t.makePublic,
                  style: const TextStyle(fontSize: 14, color: KarataColors.ink),
                ),
                subtitle: Text(
                  t.makePublicHint,
                  style: const TextStyle(fontSize: 12, color: KarataColors.dim),
                ),
              ),
            ],
            if (_isOperator && _makePublic) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: !_cashoutEnabled,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _cashoutEnabled = !value),
                title: Text(
                  t.virtualChips,
                  style: const TextStyle(fontSize: 14, color: KarataColors.ink),
                ),
                subtitle: Text(
                  t.virtualChipsHint,
                  style: const TextStyle(fontSize: 12, color: KarataColors.dim),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enforceMinimumBuyIn,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _enforceMinimumBuyIn = value),
                title: Text(
                  t.strictMinimumBuyIn,
                  style: const TextStyle(fontSize: 14, color: KarataColors.ink),
                ),
                subtitle: Text(
                  t.strictMinimumBuyInHint,
                  style: const TextStyle(fontSize: 12, color: KarataColors.dim),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoRebuyEnabled,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _autoRebuyEnabled = value),
                title: Text(
                  t.autoRebuy,
                  style: const TextStyle(fontSize: 14, color: KarataColors.ink),
                ),
                subtitle: Text(
                  t.autoRebuyHint,
                  style: const TextStyle(fontSize: 12, color: KarataColors.dim),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              t.newTableFooter,
              style: const TextStyle(
                fontSize: 12,
                color: KarataColors.dim,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _create,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KarataColors.ink,
                      ),
                    )
                  : Text(
                      _isOperator && _makePublic
                          ? t.createTable
                          : t.createAndSitDown,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
