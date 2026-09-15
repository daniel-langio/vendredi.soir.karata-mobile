import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

class CreateStandScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String username;

  const CreateStandScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.username,
  });

  @override
  State<CreateStandScreen> createState() => _CreateStandScreenState();
}

class _CreateStandScreenState extends State<CreateStandScreen> {
  late final ApiClient _apiClient;
  final _titleController = TextEditingController();
  final _contactController = TextEditingController();
  final _closedReasonController = TextEditingController();
  String _provider = 'ORANGE_MONEY';
  bool _enabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: widget.serverUrl, token: widget.token);
    _loadDefaultContact();
  }

  Future<void> _loadDefaultContact() async {
    try {
      final phone = await _apiClient.getAccountPhoneNumber();
      if (mounted && phone != null) {
        setState(() => _contactController.text = phone);
      }
    } catch (_) {
      // Non-critical - the field just starts empty if we can't reach the server.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contactController.dispose();
    _closedReasonController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final t = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final contact = _contactController.text.trim();
    final closedReason = _closedReasonController.text.trim();

    // Mirrors the server's own rule - a closed stand with no reason would give players a popup
    // with nothing to explain itself.
    if (title.isEmpty ||
        contact.isEmpty ||
        (!_enabled && closedReason.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.fillValidValues),
          backgroundColor: KarataColors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiClient.createRedemptionStand(
        title: title,
        provider: _provider,
        contact: contact,
        enabled: _enabled,
        closedReason: closedReason.isEmpty ? null : closedReason,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.couldNotCreateStand('$e')),
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
              t.newStand,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w300,
                color: KarataColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.newStandSubtitle,
              style: const TextStyle(
                fontSize: 13.5,
                color: KarataColors.dim,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.standTitleField,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KarataColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: KarataColors.ink),
              decoration: const InputDecoration(
                hintText: 'Cashout with Orange Money',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.paymentProvider,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KarataColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _provider,
              dropdownColor: KarataColors.field,
              style: const TextStyle(color: KarataColors.ink),
              items: const [
                DropdownMenuItem(value: 'MVOLA', child: Text('MVola')),
                DropdownMenuItem(
                  value: 'ORANGE_MONEY',
                  child: Text('Orange Money'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _provider = value ?? _provider),
            ),
            const SizedBox(height: 20),
            Text(
              t.standContactField,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KarataColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: KarataColors.ink),
              decoration: const InputDecoration(hintText: '+261...'),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t.standEnabledField,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KarataColors.ink,
                ),
              ),
              value: _enabled,
              activeThumbColor: KarataColors.chipInk,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            if (!_enabled) ...[
              const SizedBox(height: 12),
              Text(
                t.standClosedReasonField,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KarataColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _closedReasonController,
                maxLines: 3,
                style: const TextStyle(color: KarataColors.ink),
              ),
            ],
            const SizedBox(height: 28),
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
                  : Text(t.createStand),
            ),
          ],
        ),
      ),
    );
  }
}
