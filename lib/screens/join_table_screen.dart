import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../chip_display.dart';
import '../l10n/app_localizations.dart';
import '../theme/karata_colors.dart';
import '../theme/karata_text_styles.dart';
import '../widgets/common/amount_field.dart';
import '../widgets/common/karata_button.dart';
import '../widgets/common/karata_screen.dart';
import '../widgets/common/karata_text_field.dart';
import '../widgets/common/labeled_field.dart';
import '../widgets/join/table_preview_card.dart';

final _uuidPattern = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

class JoinTableScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const JoinTableScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<JoinTableScreen> createState() => _JoinTableScreenState();
}

class _JoinTableScreenState extends State<JoinTableScreen> {
  final _linkController = TextEditingController();
  // The buy-in is asked for in whatever unit the player reads the rest of the app in, so both the
  // default and the table's suggested buy-in are seeded through the same conversion the entry is
  // read back with. The API itself only ever speaks chips.
  final _display = ChipDisplay.instance.value;
  late final _buyInController = TextEditingController(
    text: AmountField.entryText(_display, 200),
  );

  bool _isLoading = false;
  Map<String, dynamic>? _preview;
  bool _alreadySeated = false;

  @override
  void dispose() {
    _linkController.dispose();
    _buyInController.dispose();
    super.dispose();
  }

  String? _extractGameId() =>
      _uuidPattern.firstMatch(_linkController.text)?.group(0);

  void _complain(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: KarataColors.red),
    );
  }

  Future<void> _lookUp() async {
    final gameId = _extractGameId();
    if (gameId == null) {
      _complain(AppLocalizations.of(context).noValidLink);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
      final game = await client.getGame(gameId);
      final players = (game['players'] as List<dynamic>? ?? []);
      final defaultBuyIn = (game['defaultBuyIn'] as num?)?.toInt();
      setState(() {
        _preview = game;
        _alreadySeated = players.any((p) => p['username'] == widget.username);
        // The table creator's own buy-in, kept by the server as a suggested default - if they
        // never set one, fall back to whatever was already in the field.
        if (defaultBuyIn != null) {
          _buyInController.text = AmountField.entryText(_display, defaultBuyIn);
        }
      });
    } catch (e) {
      if (mounted) {
        _complain(AppLocalizations.of(context).tableNotFound('$e'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sitDown() async {
    final gameId = _preview!['gameId'] as String;
    final client = ApiClient(baseUrl: widget.serverUrl, token: widget.token);

    setState(() => _isLoading = true);
    try {
      if (!_alreadySeated) {
        final buyIn = AmountField.chipsFrom(_display, _buyInController.text);
        if (buyIn == null || buyIn <= 0) {
          _complain(AppLocalizations.of(context).enterValidBuyIn);
          return;
        }
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
        _complain(AppLocalizations.of(context).couldNotSitDown('$e'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final preview = _preview;
    final players = (preview?['players'] as List<dynamic>? ?? []);

    return KarataScreen(
      onBack: () => Navigator.of(context).pop(),
      backLabel: t.back,
      title: t.joinTableTitle,
      subtitle: t.joinTableSubtitle,
      gap: 18,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: LabeledField(
                label: t.tableLink,
                child: KarataTextField(
                  controller: _linkController,
                  hintText: t.linkHint,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _isLoading ? null : _lookUp(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: KarataButton(
                label: t.find,
                height: 50,
                onPressed: _isLoading ? null : _lookUp,
              ),
            ),
          ],
        ),
        if (preview != null)
          TablePreviewCard(
            name: preview['name'] as String? ?? '',
            details: t.blindsSeated(
              ChipDisplay.formatWith(
                _display,
                preview['blinds']?['small'] as num?,
              ),
              ChipDisplay.formatWith(
                _display,
                preview['blinds']?['big'] as num?,
              ),
              players.length,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_alreadySeated) ...[
                  const SizedBox(height: 16),
                  LabeledField(
                    label: t.yourBuyIn,
                    child: AmountField(
                      controller: _buyInController,
                      display: _display,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.youCanOnlyBuyInOnce,
                    style: karataText(
                      size: 12,
                      weight: 500,
                      color: KarataColors.inkFaint,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                KarataButton(
                  label: _alreadySeated ? t.openTable : t.sitDown,
                  onPressed: _isLoading ? null : _sitDown,
                  height: 46,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
