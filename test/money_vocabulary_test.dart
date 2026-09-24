import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_client/chip_display.dart';
import 'package:poker_client/l10n/app_localizations.dart';

void main() {
  // Set directly rather than via setAsMoney, which would need SharedPreferences bound.
  void setMoney(bool asMoney) =>
      ChipDisplay.instance.value = ChipDisplaySettings(asMoney: asMoney);

  tearDown(() => setMoney(false));

  test('the economy speaks chips while money display is off', () {
    setMoney(false);
    const en = AppLocalizations(Locale('en'));
    const fr = AppLocalizations(Locale('fr'));

    expect(en.buyChips, 'Buy chips');
    expect(en.redeemChips, 'Redeem chips');
    expect(fr.buyChips, 'Acheter des jetons');
    expect(fr.redeemChips, 'Encaisser des jetons');
  });

  test('the economy speaks money once money display is on', () {
    setMoney(true);
    const en = AppLocalizations(Locale('en'));
    const fr = AppLocalizations(Locale('fr'));

    expect(en.buyChips, 'Deposit');
    expect(en.redeemChips, 'Withdraw');
    expect(fr.buyChips, 'Dépôt');
    expect(fr.redeemChips, 'Retrait');
  });

  test(
    'keys with no money variant keep their single wording in both modes',
    () {
      const en = AppLocalizations(Locale('en'));
      setMoney(false);
      final chipsMode = en.transactionRef;
      setMoney(true);

      expect(en.transactionRef, chipsMode);
    },
  );

  test(
    'a money variant still falls back to English for an untranslated locale',
    () {
      setMoney(true);
      // 'es' has no strings at all, so every lookup - money variants included - resolves via English.
      expect(const AppLocalizations(Locale('es')).buyChips, 'Deposit');
    },
  );
}
