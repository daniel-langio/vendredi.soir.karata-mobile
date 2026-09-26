import 'package:flutter/material.dart';
import '../chip_display.dart';

/// Hand-rolled localization: no ARB files or code generation, just a plain lookup table per
/// locale, registered through the real Localizations/LocalizationsDelegate APIs so it plugs into
/// MaterialApp exactly like a generated class would (AppLocalizations.of(context).xxx). Chosen
/// over `flutter gen-l10n` for a project this size - same result, no codegen step to maintain.
///
/// To add a language: add its Locale to [supportedLocales] and a full entry to [_strings] below
/// (copy the 'en' map as a starting point - any key missing from a non-English locale silently
/// falls back to the English string, so a partial translation never breaks the app).
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('fr')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  /// Prefers a `<key>.money` variant while chips are displayed as money, so the economy flow
  /// speaks of deposits and withdrawals rather than buying and redeeming chips. Only the keys
  /// whose wording actually changes need a `.money` entry - everything else falls straight
  /// through to the chip wording, in either mode.
  String _s(String key) {
    if (ChipDisplay.instance.value.asMoney) {
      final money = _lookup('$key.money');
      if (money != null) return money;
    }
    return _lookup(key) ?? key;
  }

  String? _lookup(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['en']![key];

  String _fmt(String key, Map<String, String> args) {
    var value = _s(key);
    args.forEach((k, v) => value = value.replaceAll('{$k}', v));
    return value;
  }

  // Common
  String get cancel => _s('cancel');
  String get logIn => _s('logIn');
  String get createAccount => _s('createAccount');
  String get required => _s('required');
  String get username => _s('username');
  String get password => _s('password');

  // WelcomeScreen
  String get welcomeTagline => _s('welcomeTagline');
  // Used by the web client's server-settings toggle only; the Android client reaches the same
  // setting through its debug backend picker. Keep them - this file is shared, and dropping
  // them here breaks the web build.
  String get serverSettings => _s('serverSettings');
  String get hideServerSettings => _s('hideServerSettings');
  String get serverBaseUrl => _s('serverBaseUrl');

  // RegisterScreen
  String get registerSubtitle => _s('registerSubtitle');
  String get usernameTooShort => _s('usernameTooShort');
  String get passwordTooShort => _s('passwordTooShort');
  String couldNotCreateAccount(String error) =>
      _fmt('couldNotCreateAccount', {'error': error});
  String promoCodeWillApply(String code) =>
      _fmt('promoCodeWillApply', {'code': code});

  // LoginScreen
  String couldNotLogIn(String error) => _fmt('couldNotLogIn', {'error': error});

  // MenuScreen
  String get signInHint => _s('signInHint');
  String get createTable => _s('createTable');
  String get joinWithLink => _s('joinWithLink');
  String get yourTables => _s('yourTables');
  String get syncedToYourAccount => _s('syncedToYourAccount');
  String get noTablesYet => _s('noTablesYet');
  String get open => _s('open');
  String get publicTables => _s('publicTables');
  String get anyoneCanSitDown => _s('anyoneCanSitDown');
  String get noPublicTables => _s('noPublicTables');
  String buyInOf(String amount) => _fmt('buyInOf', {'amount': amount});
  String seatedCount(String count) => _fmt('seatedCount', {'count': count});
  String get seatedCountOne => _s('seatedCountOne');
  String get seatedCountNone => _s('seatedCountNone');
  String couldNotLoadTables(String error) =>
      _fmt('couldNotLoadTables', {'error': error});
  String get logOut => _s('logOut');
  String get language => _s('language');
  String get systemDefault => _s('systemDefault');
  String get walletBalance => _s('walletBalance');

  // SettingsScreen
  String get settings => _s('settings');
  String get settingsGeneral => _s('settingsGeneral');
  String get settingsAccount => _s('settingsAccount');
  String get settingsTable => _s('settingsTable');
  String get chipsAsMoney => _s('chipsAsMoney');
  String get chipsAsMoneySubtitle => _s('chipsAsMoneySubtitle');
  String chipsAsMoneyExample(String chips, String money) =>
      _fmt('chipsAsMoneyExample', {'chips': chips, 'money': money});
  String get tableSounds => _s('tableSounds');
  String get tableSoundsSubtitle => _s('tableSoundsSubtitle');
  String get paymentPhoneNumber => _s('paymentPhoneNumber');
  String get paymentPhoneNumberSubtitle => _s('paymentPhoneNumberSubtitle');
  String get phoneNumberNotSet => _s('phoneNumberNotSet');
  String get savePhoneNumber => _s('savePhoneNumber');
  String get phoneNumberSaved => _s('phoneNumberSaved');
  String couldNotLoadPhoneNumber(String error) =>
      _fmt('couldNotLoadPhoneNumber', {'error': error});
  String couldNotSavePhoneNumber(String error) =>
      _fmt('couldNotSavePhoneNumber', {'error': error});

  // NewTableScreen
  String get makePublic => _s('makePublic');
  String get makePublicHint => _s('makePublicHint');
  String get virtualChips => _s('virtualChips');
  String get virtualChipsHint => _s('virtualChipsHint');
  String get strictMinimumBuyIn => _s('strictMinimumBuyIn');
  String get strictMinimumBuyInHint => _s('strictMinimumBuyInHint');
  String get autoRebuy => _s('autoRebuy');
  String get autoRebuyHint => _s('autoRebuyHint');
  String get newTableTitle => _s('newTableTitle');
  String get newTableSubtitle => _s('newTableSubtitle');
  String get name => _s('name');
  String get generateTableName => _s('generateTableName');
  String get smallBlind => _s('smallBlind');
  String get bigBlind => _s('bigBlind');
  String get yourBuyIn => _s('yourBuyIn');
  String get chips => _s('chips');
  String get newTableFooter => _s('newTableFooter');
  String get createAndSitDown => _s('createAndSitDown');
  String get fillValidValues => _s('fillValidValues');
  String couldNotCreateTable(String error) =>
      _fmt('couldNotCreateTable', {'error': error});

  // JoinTableScreen
  String get joinTableTitle => _s('joinTableTitle');
  String get joinTableSubtitle => _s('joinTableSubtitle');
  String get linkHint => _s('linkHint');
  String get find => _s('find');
  String get foundIt => _s('foundIt');
  String blindsSeated(String small, String big, int count) =>
      _fmt('blindsSeated', {'small': small, 'big': big, 'count': '$count'});
  String get youCanOnlyBuyInOnce => _s('youCanOnlyBuyInOnce');
  // Every amount field is labelled by the unit it actually takes, which follows the "show chips
  // as money" setting - so the reader never has to guess whether the number they type is chips or
  // Ar. The `.money` variants below carry the unit; the call sites just ask for the label.
  String get amount => _s('amount');
  String get sitDown => _s('sitDown');
  String get openTable => _s('openTable');
  String get noValidLink => _s('noValidLink');
  String tableNotFound(String error) => _fmt('tableNotFound', {'error': error});
  String get enterValidBuyIn => _s('enterValidBuyIn');
  String couldNotSitDown(String error) =>
      _fmt('couldNotSitDown', {'error': error});

  // TableScreen
  String get willJoinNextHand => _s('willJoinNextHand');
  String couldNotStartHand(String error) =>
      _fmt('couldNotStartHand', {'error': error});
  String actionFailed(String action, String error) =>
      _fmt('actionFailed', {'action': action, 'error': error});
  String get inviteCopied => _s('inviteCopied');
  String get closeTableTitle => _s('closeTableTitle');
  String get closeTableContent => _s('closeTableContent');
  String get closeTable => _s('closeTable');
  String get pauseTable => _s('pauseTable');
  String get resumeTable => _s('resumeTable');
  String get tablePaused => _s('tablePaused');
  String get tablePausedExplainer => _s('tablePausedExplainer');
  String couldNotPauseTable(String error) =>
      _fmt('couldNotPauseTable', {'error': error});
  String get addBot => _s('addBot');
  String get addBotTitle => _s('addBotTitle');
  String get botStrategyServerChoice => _s('botStrategyServerChoice');
  String get botStrategyCautious => _s('botStrategyCautious');
  String get botStrategyBalanced => _s('botStrategyBalanced');
  String get botStrategyAggressive => _s('botStrategyAggressive');
  String couldNotAddBot(String error) =>
      _fmt('couldNotAddBot', {'error': error});
  String get closedSuffix => _s('closedSuffix');
  String couldNotCloseTable(String error) =>
      _fmt('couldNotCloseTable', {'error': error});
  String get leaveTableTitle => _s('leaveTableTitle');
  String get leaveTableContent => _s('leaveTableContent');
  String get leaveTable => _s('leaveTable');
  String couldNotLeaveTable(String error) =>
      _fmt('couldNotLeaveTable', {'error': error});
  String get copyInvite => _s('copyInvite');
  String get live => _s('live');
  String get reconnecting => _s('reconnecting');
  String lastUpdateAgo(int secs) => _fmt('lastUpdateAgo', {'secs': '$secs'});
  String yourTurnLeft(int secs) => _fmt('yourTurnLeft', {'secs': '$secs'});
  String waitingOn(String username) =>
      _fmt('waitingOn', {'username': username});
  String get tableClosed => _s('tableClosed');
  String get waitingForDraw => _s('waitingForDraw');
  String get standPat => _s('standPat');
  String drawCards(int count) => _fmt('drawCards', {'count': '$count'});
  String get tapCardsToDiscard => _s('tapCardsToDiscard');
  String get startTheHand => _s('startTheHand');
  String get nextHand => _s('nextHand');
  String get fold => _s('fold');
  String get check => _s('check');
  // Left untranslated in both locales - "action" is used as an international poker-room loanword
  // for "it's your/their turn", same as how "check" itself gets no French translation above.
  String get onTheClock => _s('onTheClock');
  // Amounts arrive pre-formatted (via ChipDisplay) rather than as raw ints, the same convention
  // as buyInOf - so a caller controls whether the reader sees a chip count or its money reading.
  String call(String amount) => _fmt('call', {'amount': amount});
  String bet(String amount) => _fmt('bet', {'amount': amount});
  String raise(String amount) => _fmt('raise', {'amount': amount});
  // Bare verbs for the action buttons, which stack the amount on a second line - a third of a
  // phone's width can't hold "Relancer 7 600 Ar" on one, and an ellipsis hides the very number
  // the player is about to commit.
  String get callVerb => _s('callVerb');
  String get betVerb => _s('betVerb');
  String get raiseVerb => _s('raiseVerb');
  String minAllIn(String min, String max) =>
      _fmt('minAllIn', {'min': min, 'max': max});
  String get oneThirdPot => _s('oneThirdPot');
  String get halfPot => _s('halfPot');
  String get threeQuartersPot => _s('threeQuartersPot');
  String get pot => _s('pot');
  String get allIn => _s('allIn');
  String get handStrengthAvailableSoon => _s('handStrengthAvailableSoon');

  /// Three separate keys rather than one, because French has to agree with its subject: the
  /// winner speaks in the second person ("tu remportes"), anyone else in the third ("il
  /// remporte"), and several winners in the plural ("remportent"). English uses "won" throughout.
  String won(String names, String amount) =>
      _fmt('won', {'names': names, 'amount': amount});
  String wonByYou(String amount) => _fmt('wonByYou', {'amount': amount});
  String wonBySeveral(String names, String amount) =>
      _fmt('wonBySeveral', {'names': names, 'amount': amount});
  String get winnerTag => _s('winnerTag');
  String get sb => _s('sb');
  String get bb => _s('bb');
  String get allInTag => _s('allInTag');
  String get you => _s('you');
  String get playing => _s('playing');
  String get spectating => _s('spectating');
  String get gameVariant => _s('gameVariant');
  String get variantTitle => _s('variantTitle');
  String get variantName => _s('variantName');
  String get variantHoleCards => _s('variantHoleCards');
  String get variantBoard => _s('variantBoard');
  String get variantBetting => _s('variantBetting');
  String get variantRanking => _s('variantRanking');
  String get variantTitleOmaha => _s('variantTitleOmaha');
  String get variantHoleCardsOmaha => _s('variantHoleCardsOmaha');
  String get variantRankingOmaha => _s('variantRankingOmaha');
  String get variantTexasHoldemShort => _s('variantTexasHoldemShort');
  String get variantOmahaShort => _s('variantOmahaShort');
  String get variantTitleFiveCardDraw => _s('variantTitleFiveCardDraw');
  String get variantHoleCardsFiveCardDraw => _s('variantHoleCardsFiveCardDraw');
  String get variantRankingFiveCardDraw => _s('variantRankingFiveCardDraw');
  String get variantDrawPhase => _s('variantDrawPhase');
  String get variantFiveCardDrawShort => _s('variantFiveCardDrawShort');
  String get variantSevenCardStudShort => _s('variantSevenCardStudShort');
  String get comingSoon => _s('comingSoon');
  String get variantSimplificationsHeading =>
      _s('variantSimplificationsHeading');
  String get variantNoSidePots => _s('variantNoSidePots');
  String get variantSimplifiedMinRaise => _s('variantSimplifiedMinRaise');
  String get close => _s('close');

  // EconomyScreen
  String get economyTitle => _s('economyTitle');
  String get economySubtitle => _s('economySubtitle');
  String buyPriceLine(String price) => _fmt('buyPriceLine', {'price': price});
  String sellPriceLine(String price) => _fmt('sellPriceLine', {'price': price});
  String get buyChips => _s('buyChips');
  String get redeemChips => _s('redeemChips');
  String get pendingRedemptions => _s('pendingRedemptions');
  String get economySettings => _s('economySettings');
  String couldNotLoadPrice(String error) =>
      _fmt('couldNotLoadPrice', {'error': error});

  // ChipPurchaseScreen
  String get quantity => _s('quantity');
  String get paymentProvider => _s('paymentProvider');
  String payInstructions(String amount, String phone) =>
      _fmt('payInstructions', {'amount': amount, 'phone': phone});
  String get yourPhoneNumber => _s('yourPhoneNumber');
  String get transactionRef => _s('transactionRef');
  String get transactionRefHint => _s('transactionRefHint');
  String get submitPayment => _s('submitPayment');
  String get waitingForConfirmation => _s('waitingForConfirmation');
  String get chipsCredited => _s('chipsCredited');
  String couldNotBuyChips(String error) =>
      _fmt('couldNotBuyChips', {'error': error});

  // ChipRedemptionScreen
  String get payoutPhoneNumber => _s('payoutPhoneNumber');
  String redeemTotalLine(String amount) =>
      _fmt('redeemTotalLine', {'amount': amount});
  String get submitRedemption => _s('submitRedemption');
  String get waitingForPayout => _s('waitingForPayout');
  String get redemptionPaidOut => _s('redemptionPaidOut');
  String get redemptionCancelled => _s('redemptionCancelled');
  String couldNotRedeemChips(String error) =>
      _fmt('couldNotRedeemChips', {'error': error});

  // EconomyConfigScreen
  String get chipPriceField => _s('chipPriceField');
  String get savePrice => _s('savePrice');
  String get priceUpdated => _s('priceUpdated');
  String couldNotUpdatePrice(String error) =>
      _fmt('couldNotUpdatePrice', {'error': error});
  String get sellSpreadPercentField => _s('sellSpreadPercentField');
  String get rakePercentField => _s('rakePercentField');
  String get rakeMinField => _s('rakeMinField');
  String get houseReceivingPhoneNumberField =>
      _s('houseReceivingPhoneNumberField');
  String get saveConfig => _s('saveConfig');
  String get configUpdated => _s('configUpdated');
  String couldNotUpdateConfig(String error) =>
      _fmt('couldNotUpdateConfig', {'error': error});

  // PendingRedemptionsScreen
  String get pendingRedemptionsSubtitle => _s('pendingRedemptionsSubtitle');
  String get noPendingRedemptions => _s('noPendingRedemptions');
  String couldNotLoadPendingRedemptions(String error) =>
      _fmt('couldNotLoadPendingRedemptions', {'error': error});
  String get cancelRedemptionTitle => _s('cancelRedemptionTitle');
  String get cancelRedemptionContent => _s('cancelRedemptionContent');
  String get cancelRedemptionButton => _s('cancelRedemptionButton');
  String couldNotCancelRedemption(String error) =>
      _fmt('couldNotCancelRedemption', {'error': error});

  // V2 design - common chrome and the auth screens
  String get back => _s('back');
  String get usernameHint => _s('usernameHint');
  String get passwordHint => _s('passwordHint');
  String get showPassword => _s('showPassword');
  String get loginSubtitle => _s('loginSubtitle');
  String get alreadyHaveAnAccount => _s('alreadyHaveAnAccount');
  String get newHere => _s('newHere');

  // V2 design - joining a table
  String get tableLink => _s('tableLink');

  // V2 design - the lobby and the balance card
  String get balance => _s('balance');
  String get atTables => _s('atTables');
  String get deposit => _s('deposit');
  String get withdraw => _s('withdraw');
  String get seatsOpen => _s('seatsOpen');

  // V2 design - creating a table
  String get table => _s('table');
  String bigBlindsPreset(String count) =>
      _fmt('bigBlindsPreset', {'count': count});
  String get maxPreset => _s('maxPreset');
  String thatsNBigBlinds(String count) =>
      _fmt('thatsNBigBlinds', {'count': count});
  String balanceOf(String amount) => _fmt('balanceOf', {'amount': amount});

  // V2 design - the wallet
  String get house => _s('house');
  String get admin => _s('admin');
  String get refresh => _s('refresh');
  String get pendingRedemptionsHint => _s('pendingRedemptionsHint');
  String get economySettingsHint => _s('economySettingsHint');

  // V2 design - deposits and withdrawals
  String get chipsYouGet => _s('chipsYouGet');
  String get fee => _s('fee');
  String get youPay => _s('youPay');
  String get sendThePayment => _s('sendThePayment');
  String get confirmItHere => _s('confirmItHere');
  String get copyNumber => _s('copyNumber');
  String get numberCopied => _s('numberCopied');
  String get depositSubtitle => _s('depositSubtitle');

  // V2 design - withdrawals
  String get withdrawSubtitle => _s('withdrawSubtitle');
  String get allPreset => _s('allPreset');
  String get chipsBurned => _s('chipsBurned');
  String get youWillReceive => _s('youWillReceive');
  String get payoutsByHand => _s('payoutsByHand');

  // V2 design - pending payouts
  String get owedInTotal => _s('owedInTotal');
  String get toSend => _s('toSend');
  String nPending(String count) => _fmt('nPending', {'count': count});

  // V2 design - economy settings
  String get chipPrice => _s('chipPrice');
  String get price => _s('price');
  String get arPerChip => _s('arPerChip');
  String get fees => _s('fees');
  String get houseAccount => _s('houseAccount');
  String get receivingPhoneNumber => _s('receivingPhoneNumber');
  String get noMinimum => _s('noMinimum');

  // V2 design - the table
  String get winner => _s('winner');
  String get yourTurnBadge => _s('yourTurnBadge');
  String get handStrength => _s('handStrength');
  String get sendReaction => _s('sendReaction');
  String get betAmount => _s('betAmount');
  String get tablePausedHost => _s('tablePausedHost');

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'cancel': 'Cancel',
      'logIn': 'Log in',
      'createAccount': 'Create account',
      'required': 'Required',
      'username': 'Username',
      'password': 'Password',
      'welcomeTagline':
          'Play poker with your friends. No accounts to manage, just a name and a table.',
      'serverSettings': 'Server settings',
      'hideServerSettings': 'Hide server settings',
      'serverBaseUrl': 'Server base URL',
      'registerSubtitle':
          'This name is how everyone else at the table will see you.',
      'usernameTooShort': 'At least 3 characters',
      'passwordTooShort': 'At least 6 characters',
      'couldNotCreateAccount': 'Could not create account: {error}',
      'promoCodeWillApply':
          'Promo code {code} will be applied to your account.',
      'couldNotLogIn': 'Could not log in: {error}',
      'signInHint': 'This name is your sign-in',
      'createTable': 'New table',
      'joinWithLink': 'Join with link',
      'yourTables': 'Your tables',
      'syncedToYourAccount': 'synced to your account',
      'makePublic': 'Make this table public',
      'makePublicHint':
          'Listed on everyone’s home screen and hosted by the house. You won’t be seated, and it can’t be paused or closed.',
      'virtualChips': 'Virtual chips (no real money)',
      'virtualChipsHint':
          'Chips here are free and can never be cashed out - use this for a practice/demo table.',
      'strictMinimumBuyIn': 'Enforce minimum buy-in',
      'strictMinimumBuyInHint':
          'Players must buy in for at least the tier amount above.',
      'autoRebuy': 'Auto-rebuy busted players',
      'autoRebuyHint':
          'Whenever an active player runs out of chips, the house tops them back up before '
          'the next hand - useful with a permanent bot opponent.',
      'publicTables': 'Public tables',
      'anyoneCanSitDown': 'Anyone can sit down',
      'noPublicTables': 'No public tables are open right now.',
      'buyInOf': '{amount} buy-in',
      'seatedCount': '{count} players',
      'seatedCountOne': '1 player',
      'seatedCountNone': 'empty',
      'couldNotLoadTables': 'Could not load your tables: {error}',
      'noTablesYet': 'No tables yet. Create or join one to see it here.',
      'open': 'Open',
      'logOut': 'Log out',
      'language': 'Language',
      'systemDefault': 'System default',
      'walletBalance': 'Wallet balance - tap to open the marketplace',
      'newTableTitle': 'New table',
      'newTableSubtitle':
          'Name and blinds are all the server keeps. Everything else is set when each player sits down.',
      'name': 'Name',
      'generateTableName': 'Suggest another name',
      'smallBlind': 'Small blind',
      'bigBlind': 'Big blind',
      'yourBuyIn': 'Your buy-in',
      'chips': 'Chips',
      'newTableFooter':
          'Creating the table seats you at it. Everyone else picks their own buy-in when they join, and chips carry between hands.',
      'createAndSitDown': 'Create and sit down',
      'fillValidValues': 'Please fill in valid values',
      'couldNotCreateTable': 'Could not create table: {error}',
      'joinTableTitle': 'Join a table',
      'joinTableSubtitle':
          'Paste the link someone sent you. Table IDs are long, so nobody should ever have to read one out.',
      'linkHint': 'karata.app/t/…',
      'find': 'Find',
      'foundIt': 'Found it',
      'blindsSeated': 'Blinds {small} / {big} · {count} seated',
      'youCanOnlyBuyInOnce':
          "You can only buy in once per table, so pick a stack you're happy to sit with.",
      'amount': 'Amount',
      'sitDown': 'Sit down',
      'openTable': 'Open table',
      'noValidLink': 'No valid table link found',
      'tableNotFound': 'Table not found: {error}',
      'enterValidBuyIn': 'Enter a valid buy-in',
      'couldNotSitDown': 'Could not sit down: {error}',
      'willJoinNextHand': "You'll be dealt in once this hand ends",
      'couldNotStartHand': 'Could not start hand: {error}',
      'actionFailed': '{action} failed: {error}',
      'inviteCopied': 'Invite copied — send it to whoever you want to invite',
      'closeTableTitle': 'Close this table?',
      'closeTableContent':
          'Nobody will be able to join, start a hand, or act at this table again. This cannot be undone.',
      'closeTable': 'Close table',
      'pauseTable': 'Pause table',
      'resumeTable': 'Resume table',
      'tablePaused': 'The host has paused this table.',
      'tablePausedExplainer':
          'No deals or actions until the host resumes. Your chips stay where they are.',
      'couldNotPauseTable': 'Could not change the pause state: {error}',
      'addBot': 'Add a bot',
      'addBotTitle': 'Add a bot',
      'botStrategyServerChoice': 'Let the house choose',
      'botStrategyCautious': 'Cautious',
      'botStrategyBalanced': 'Balanced',
      'botStrategyAggressive': 'Aggressive',
      'couldNotAddBot': 'Could not add a bot: {error}',
      'closedSuffix': 'closed',
      'couldNotCloseTable': 'Could not close table: {error}',
      'leaveTableTitle': 'Leave this table?',
      'leaveTableContent':
          "You'll be folded out of the current hand if you're still in it, and won't be dealt into any future ones here. You can't sit back down afterwards.",
      'leaveTable': 'Leave table',
      'couldNotLeaveTable': 'Could not leave table: {error}',
      'copyInvite': 'Copy invite',
      'live': 'Live',
      'reconnecting': 'Reconnecting',
      'lastUpdateAgo': 'Last update {secs}s ago',
      'yourTurnLeft': 'Your turn — {secs}s left',
      'waitingOn': 'Waiting on {username}',
      'tableClosed': 'THIS TABLE IS CLOSED',
      'waitingForDraw': 'Waiting for the draw...',
      'standPat': 'Stand pat',
      'drawCards': 'Draw {count}',
      'tapCardsToDiscard': 'Tap cards to discard, then draw',
      'startTheHand': 'Start the hand',
      'nextHand': 'Next hand',
      'fold': 'Fold',
      'check': 'Check',
      'onTheClock': 'ACTION',
      'call': 'Call {amount}',
      'bet': 'Bet {amount}',
      'raise': 'Raise {amount}',
      'callVerb': 'Call',
      'betVerb': 'Bet',
      'raiseVerb': 'Raise',
      'minAllIn': 'min {min} · all in {max}',
      'oneThirdPot': '1/3',
      'halfPot': '1/2',
      'threeQuartersPot': '3/4',
      'pot': 'Pot',
      'allIn': 'All-in',
      'handStrengthAvailableSoon': 'Hand strength\navailable soon',
      'won': '{names} won {amount}',
      'wonByYou': 'You won {amount}',
      'wonBySeveral': '{names} won {amount}',
      'winnerTag': 'WINNER',
      'sb': 'SB',
      'bb': 'BB',
      'allInTag': 'ALL',
      'you': 'You',
      'playing': 'Playing',
      'spectating': 'Spectating',
      'gameVariant': 'Game variant',
      'variantTitle': 'No-Limit Texas Hold\'em',
      'variantName': 'No-Limit Texas Hold\'em',
      'variantHoleCards': '2 hole cards per player, dealt face down',
      'variantBoard':
          '5 shared community cards, revealed in three stages: flop (3), turn (1), river (1)',
      'variantBetting':
          'No-limit betting - you can raise up to your entire stack at any time',
      'variantRanking':
          'Best 5-card hand using any combination of your hole cards and the board',
      'variantTitleOmaha': 'No-Limit Omaha',
      'variantHoleCardsOmaha': '4 hole cards per player, dealt face down',
      'variantRankingOmaha':
          'Best 5-card hand using exactly 2 of your hole cards and exactly 3 from the board',
      'variantTexasHoldemShort': 'No-limit Texas Hold\'em',
      'variantOmahaShort': 'Pot-limit Omaha',
      'variantTitleFiveCardDraw': 'No-Limit Five-Card Draw',
      'variantHoleCardsFiveCardDraw':
          '5 hole cards per player, dealt face down',
      'variantDrawPhase':
          'No shared community cards - after the first betting round, each player may discard 0-5 cards and draw replacements, then a second betting round',
      'variantRankingFiveCardDraw': 'Best 5-card hand using your own 5 cards',
      'variantFiveCardDrawShort': 'Five-Card Draw',
      'variantSevenCardStudShort': 'Seven-Card Stud',
      'comingSoon': 'Soon',
      'variantSimplificationsHeading': 'This table simplifies a few things',
      'variantNoSidePots':
          'No side pots - an all-in tie splits the whole pot evenly, regardless of stack size',
      'variantSimplifiedMinRaise':
          'Minimum raise is simplified (double the current bet), not the standard last-raise-size rule',
      'close': 'Close',
      'economyTitle': 'Wallet',
      'economyTitle.money': 'Wallet',
      'economySubtitle':
          'Deposit to top up your balance, or withdraw it back to mobile money.',
      'economySubtitle.money':
          'Deposit to top up your balance, or withdraw it back to mobile money.',
      'buyPriceLine': 'Redeem rate: {price} Ar per chip',
      'sellPriceLine': 'Buy rate: {price} Ar per chip',
      'buyChips': 'Buy chips',
      'buyChips.money': 'Deposit',
      'redeemChips': 'Redeem chips',
      'redeemChips.money': 'Withdraw',
      'pendingRedemptions': 'Pending withdrawals',
      'pendingRedemptions.money': 'Pending withdrawals',
      'economySettings': 'Economy settings',
      'couldNotLoadPrice': 'Could not load the chip price: {error}',
      'couldNotLoadPrice.money': 'Could not load the rate: {error}',
      'quantity': 'Quantity',
      'quantity.money': 'Amount (Ar)',
      'paymentProvider': 'Payment provider',
      'payInstructions': 'Pay {amount} to {phone} from your mobile money app.',
      'yourPhoneNumber': 'Your phone number',
      'transactionRef': 'Transaction reference',
      'transactionRefHint': 'Ref or Trans Id from your SMS',
      'submitPayment': 'I’ve paid',
      'waitingForConfirmation': 'Waiting for the payment to be confirmed...',
      'chipsCredited': 'Chips credited to your wallet!',
      'chipsCredited.money': 'Deposit credited to your wallet!',
      'couldNotBuyChips': 'Could not submit payment: {error}',
      'payoutPhoneNumber': 'Payout phone number',
      'redeemTotalLine': 'You will receive {amount} Ar',
      'submitRedemption': 'Redeem chips',
      'submitRedemption.money': 'Withdraw',
      'waitingForPayout': 'Waiting for the payout to be confirmed...',
      'redemptionPaidOut': 'Redemption paid out!',
      'redemptionPaidOut.money': 'Withdrawal paid out!',
      'redemptionCancelled': 'Redemption cancelled - your chips were refunded.',
      'redemptionCancelled.money':
          'Withdrawal cancelled - your balance was refunded.',
      'couldNotRedeemChips': 'Could not submit redemption: {error}',
      'couldNotRedeemChips.money': 'Could not submit withdrawal: {error}',
      'chipPriceField': 'Chip price (Ar per chip)',
      'savePrice': 'Save price',
      'priceUpdated': 'Price updated',
      'couldNotUpdatePrice': 'Could not update the price: {error}',
      'sellSpreadPercentField': 'Sell spread',
      'rakePercentField': 'Table rake',
      'rakeMinField': 'Table rake minimum',
      'houseReceivingPhoneNumberField': 'House receiving phone number',
      'saveConfig': 'Save config',
      'configUpdated': 'Config updated',
      'couldNotUpdateConfig': 'Could not update the config: {error}',
      'pendingRedemptionsSubtitle':
          'Chips already burned, payout still owed. Send these by hand.',
      'noPendingRedemptions': 'No pending redemptions.',
      'couldNotLoadPendingRedemptions':
          'Could not load pending redemptions: {error}',
      'cancelRedemptionTitle': 'Cancel this redemption?',
      'cancelRedemptionContent': "The player's chips will be refunded.",
      'cancelRedemptionButton': 'Cancel redemption',
      'couldNotCancelRedemption': 'Could not cancel redemption: {error}',
      'settings': 'Settings',
      'settingsGeneral': 'General',
      'settingsAccount': 'Account',
      'settingsTable': 'Table',
      'chipsAsMoney': 'Show chips as money',
      'chipsAsMoneySubtitle':
          'Show every chip count in Ariary. This is your own valuation, not an official rate.',
      'chipsAsMoneyExample': '{chips} chips shows as {money}',
      'tableSounds': 'Table sounds',
      'tableSoundsSubtitle': 'Card, chip and button sounds during a hand.',
      'paymentPhoneNumber': 'Payment phone number',
      'paymentPhoneNumberSubtitle':
          'Used to pay for chips you buy and to receive payment for chips you sell.',
      'phoneNumberNotSet': 'Not set yet',
      'savePhoneNumber': 'Save number',
      'phoneNumberSaved': 'Phone number saved',
      'couldNotLoadPhoneNumber': 'Could not load your phone number: {error}',
      'couldNotSavePhoneNumber': 'Could not save your phone number: {error}',
      'back': 'Back',
      'usernameHint': 'Your table name',
      'passwordHint': 'At least 8 characters',
      'showPassword': 'Show password',
      'loginSubtitle': 'Welcome back.',
      'alreadyHaveAnAccount': 'Already have an account?',
      'newHere': 'New here?',
      'tableLink': 'Table link',
      'balance': 'Balance',
      'atTables': 'At tables',
      'deposit': 'Deposit',
      'withdraw': 'Withdraw',
      'seatsOpen': 'Seats open',
      'table': 'Table',
      'bigBlindsPreset': '{count} BB',
      'maxPreset': 'Max',
      'thatsNBigBlinds': 'That’s {count} big blinds.',
      'balanceOf': 'Balance: {amount}',
      'house': 'House',
      'admin': 'Admin',
      'refresh': 'Refresh',
      'pendingRedemptionsHint': 'Payouts you still owe players',
      'economySettingsHint': 'Chip price, spread and rake',
      'chipsYouGet': 'Chips you get',
      'fee': 'Fee',
      'youPay': 'You pay',
      'sendThePayment': 'Send the payment',
      'confirmItHere': 'Confirm it here',
      'copyNumber': 'Copy number',
      'numberCopied': 'Number copied',
      'depositSubtitle': 'Top up with mobile money.',
      'withdrawSubtitle': 'Send your balance back to mobile money.',
      'allPreset': 'All',
      'chipsBurned': 'Chips burned',
      'youWillReceive': 'You will receive',
      'payoutsByHand': 'Payouts are sent by hand, usually within a day.',
      'owedInTotal': 'Owed in total',
      'toSend': 'To send',
      'nPending': '{count} pending',
      'chipPrice': 'Chip price',
      'price': 'Price',
      'arPerChip': 'Ar per chip',
      'fees': 'Fees',
      'houseAccount': 'House account',
      'receivingPhoneNumber': 'Receiving phone number',
      'noMinimum': 'No minimum',
      'winner': 'Winner',
      'yourTurnBadge': 'Your turn',
      'handStrength': 'Hand strength',
      'sendReaction': 'Send a reaction',
      'betAmount': 'Bet amount',
      'tablePausedHost':
          'You have paused this table. Nobody can act until you resume it.',
    },
    'fr': {
      'cancel': 'Annuler',
      'logIn': 'Se connecter',
      'createAccount': 'Créer un compte',
      'required': 'Requis',
      'username': "Nom d'utilisateur",
      'password': 'Mot de passe',
      'welcomeTagline':
          'Jouez au poker avec vos amis. Pas de compte à gérer, juste un nom et une table.',
      'serverSettings': 'Paramètres du serveur',
      'hideServerSettings': 'Masquer les paramètres du serveur',
      'serverBaseUrl': 'URL de base du serveur',
      'registerSubtitle':
          'Ce nom est celui que tous les autres joueurs verront à la table.',
      'usernameTooShort': 'Au moins 3 caractères',
      'passwordTooShort': 'Au moins 6 caractères',
      'couldNotCreateAccount': 'Impossible de créer le compte : {error}',
      'promoCodeWillApply':
          'Le code promo {code} sera appliqué à votre compte.',
      'couldNotLogIn': 'Impossible de se connecter : {error}',
      'signInHint': 'Ce nom est votre identifiant de connexion',
      'createTable': 'Nouvelle table',
      'joinWithLink': 'Rejoindre par lien',
      'yourTables': 'Vos tables',
      'syncedToYourAccount': 'synchronisées avec votre compte',
      'makePublic': 'Rendre cette table publique',
      'makePublicHint':
          'Listée sur l\'écran d\'accueil de tous et hébergée par la maison. Vous n\'y serez pas assis, et elle ne peut être ni mise en pause ni fermée.',
      'virtualChips': 'Jetons virtuels (pas d\'argent réel)',
      'virtualChipsHint':
          'Les jetons ici sont gratuits et ne peuvent jamais être encaissés - à utiliser pour '
          'une table de démonstration.',
      'strictMinimumBuyIn': 'Imposer la cave minimale',
      'strictMinimumBuyInHint':
          'Les joueurs doivent se recaver pour au moins le montant du palier ci-dessus.',
      'autoRebuy': 'Recave automatique des joueurs ruinés',
      'autoRebuyHint':
          'Quand un joueur actif n\'a plus de jetons, la maison le recave avant la prochaine '
          'main - utile avec un bot adversaire permanent.',
      'publicTables': 'Tables publiques',
      'anyoneCanSitDown': 'Tout le monde peut s\'asseoir',
      'noPublicTables': 'Aucune table publique n\'est ouverte pour le moment.',
      'buyInOf': 'cave de {amount}',
      'seatedCount': '{count} joueurs',
      'seatedCountOne': '1 joueur',
      'seatedCountNone': 'vide',
      'couldNotLoadTables': 'Impossible de charger vos tables : {error}',
      'noTablesYet':
          'Aucune table pour le moment. Créez-en une ou rejoignez-en une pour la voir ici.',
      'open': 'Ouvrir',
      'logOut': 'Se déconnecter',
      'language': 'Langue',
      'systemDefault': 'Système',
      'walletBalance': 'Solde du portefeuille - touchez pour ouvrir le marché',
      'newTableTitle': 'Nouvelle table',
      'newTableSubtitle':
          'Le serveur ne retient que le nom et les blindes. Tout le reste se règle quand chaque joueur s\'assoit.',
      'name': 'Nom',
      'generateTableName': 'Proposer un autre nom',
      'smallBlind': 'Petite blinde',
      'bigBlind': 'Grosse blinde',
      'yourBuyIn': "Votre mise d'entrée",
      'chips': 'Jetons',
      'newTableFooter':
          'Créer la table vous y installe. Chacun choisit sa propre cave en rejoignant, et les jetons se reportent d\'une main à l\'autre.',
      'createAndSitDown': "Créer et s'installer",
      'fillValidValues': 'Veuillez saisir des valeurs valides',
      'couldNotCreateTable': 'Impossible de créer la table : {error}',
      'joinTableTitle': 'Rejoindre une table',
      'joinTableSubtitle':
          'Collez le lien qu\'on vous a envoyé. Les identifiants de table sont longs : personne ne devrait avoir à en dicter un.',
      'linkHint': 'karata.app/t/…',
      'find': 'Rechercher',
      'foundIt': 'Trouvée',
      'blindsSeated': 'Blindes {small} / {big} · {count} joueurs',
      'youCanOnlyBuyInOnce':
          "Vous ne pouvez acheter des jetons qu'une seule fois par table : choisissez une pile qui vous convient.",
      'amount': 'Montant',
      'sitDown': "S'installer",
      'openTable': 'Ouvrir la table',
      'noValidLink': 'Aucun lien de table valide trouvé',
      'tableNotFound': 'Table introuvable : {error}',
      'enterValidBuyIn': "Saisissez une mise d'entrée valide",
      'couldNotSitDown': "Impossible de s'installer : {error}",
      'willJoinNextHand': 'Vous serez servi une fois cette main terminée',
      'couldNotStartHand': 'Impossible de démarrer la main : {error}',
      'actionFailed': '{action} a échoué : {error}',
      'inviteCopied':
          "Invitation copiée — envoyez-la à qui vous voulez inviter",
      'closeTableTitle': 'Fermer cette table ?',
      'closeTableContent':
          'Plus personne ne pourra rejoindre, démarrer une main ni jouer à cette table. Cette action est irréversible.',
      'closeTable': 'Fermer la table',
      'pauseTable': 'Mettre la table en pause',
      'resumeTable': 'Reprendre la partie',
      'tablePaused': 'L\'hôte a mis cette table en pause.',
      'tablePausedExplainer':
          'Aucune donne ni action tant que l\'hôte n\'a pas repris. Vos jetons restent en place.',
      'couldNotPauseTable': 'Impossible de changer l\'état de pause : {error}',
      'addBot': 'Ajouter un bot',
      'addBotTitle': 'Ajouter un bot',
      'botStrategyServerChoice': 'Laisser la maison choisir',
      'botStrategyCautious': 'Prudent',
      'botStrategyBalanced': 'Équilibré',
      'botStrategyAggressive': 'Agressif',
      'couldNotAddBot': "Impossible d'ajouter un bot : {error}",
      'closedSuffix': 'fermée',
      'couldNotCloseTable': 'Impossible de fermer la table : {error}',
      'leaveTableTitle': 'Quitter cette table ?',
      'leaveTableContent':
          "Vous serez couché de la main en cours si vous y êtes encore, et vous ne serez plus distribué dans les mains suivantes ici. Vous ne pourrez pas vous rasseoir ensuite.",
      'leaveTable': 'Quitter la table',
      'couldNotLeaveTable': 'Impossible de quitter la table : {error}',
      'copyInvite': "Copier l'invitation",
      'live': 'En direct',
      'reconnecting': 'Reconnexion',
      'lastUpdateAgo': 'Dernière mise à jour il y a {secs} s',
      // Trimmed of "restantes": this sits in a row with the dealer chip and the turn badge, and
      // the countdown is the part that must survive, not the last word of the sentence.
      'yourTurnLeft': 'À vous de jouer — {secs} s',
      'waitingOn': 'En attente de {username}',
      'tableClosed': 'CETTE TABLE EST FERMÉE',
      'waitingForDraw': 'En attente de la pioche...',
      'standPat': 'Garder sa main',
      'drawCards': 'Piocher {count}',
      'tapCardsToDiscard': 'Touchez les cartes à défausser, puis piochez',
      'startTheHand': 'Démarrer la main',
      'nextHand': 'Main suivante',
      'fold': 'Se coucher',
      'check': 'Check',
      'onTheClock': 'ACTION',
      'call': 'Suivre {amount}',
      'bet': 'Miser {amount}',
      'raise': 'Relancer {amount}',
      'callVerb': 'Suivre',
      'betVerb': 'Miser',
      'raiseVerb': 'Relancer',
      'minAllIn': 'min {min} · tapis {max}',
      'oneThirdPot': '1/3',
      'halfPot': '1/2',
      'threeQuartersPot': '3/4',
      'pot': 'Pot',
      'allIn': 'Tapis',
      'handStrengthAvailableSoon': 'Force de la main\nbientôt disponible',
      'won': '{names} remporte {amount}',
      'wonByYou': 'Tu remportes {amount}',
      'wonBySeveral': '{names} remportent {amount}',
      'winnerTag': 'GAGNANT',
      'sb': 'PB',
      'bb': 'GB',
      'allInTag': 'TAPIS',
      'you': 'Toi',
      'playing': 'En jeu',
      'spectating': 'Spectateur',
      'gameVariant': 'Variante jouée',
      'variantTitle': 'Texas Hold\'em sans limite',
      'variantName': 'Texas Hold\'em sans limite',
      'variantHoleCards':
          '2 cartes fermées par joueur, distribuées face cachée',
      'variantBoard':
          '5 cartes communes partagées, révélées en trois temps : flop (3), turn (1), river (1)',
      'variantBetting':
          'Mises sans limite - vous pouvez relancer jusqu\'à tout votre tapis à tout moment',
      'variantRanking':
          'Meilleure main de 5 cartes parmi vos cartes et le tableau, dans n\'importe quelle combinaison',
      'variantTitleOmaha': 'Omaha sans limite',
      'variantHoleCardsOmaha':
          '4 cartes fermées par joueur, distribuées face cachée',
      'variantRankingOmaha':
          'Meilleure main de 5 cartes en utilisant exactement 2 de vos cartes fermées et exactement 3 du tableau',
      'variantTexasHoldemShort': 'Texas Hold\'em no-limit',
      'variantOmahaShort': 'Omaha pot-limit',
      'variantTitleFiveCardDraw': 'Five-Card Draw sans limite',
      'variantHoleCardsFiveCardDraw':
          '5 cartes fermées par joueur, distribuées face cachée',
      'variantDrawPhase':
          'Pas de cartes communes - après le premier tour de mises, chaque joueur peut défausser 0 à 5 cartes et en piocher autant, puis un second tour de mises',
      'variantRankingFiveCardDraw':
          'Meilleure main de 5 cartes parmi vos propres cartes',
      'variantFiveCardDrawShort': 'Five-Card Draw',
      'variantSevenCardStudShort': 'Seven-Card Stud',
      'comingSoon': 'Bientôt',
      'variantSimplificationsHeading': 'Cette table simplifie quelques règles',
      'variantNoSidePots':
          'Pas de pots secondaires - une égalité à tapis partage tout le pot également, peu importe la taille des tapis',
      'variantSimplifiedMinRaise':
          'Relance minimale simplifiée (le double de la mise actuelle), pas la règle standard de la taille de la dernière relance',
      'close': 'Fermer',
      'economyTitle': 'Portefeuille',
      'economyTitle.money': 'Portefeuille',
      'economySubtitle':
          'Déposez pour recharger votre solde, ou retirez-le vers le mobile money.',
      'economySubtitle.money':
          'Déposez pour recharger votre solde, ou retirez-le vers mobile money.',
      'buyPriceLine': "Taux d'encaissement : {price} Ar par jeton",
      'sellPriceLine': "Taux d'achat : {price} Ar par jeton",
      'buyChips': 'Acheter des jetons',
      'buyChips.money': 'Dépôt',
      'redeemChips': 'Encaisser des jetons',
      'redeemChips.money': 'Retrait',
      'pendingRedemptions': 'Retraits en attente',
      'pendingRedemptions.money': 'Retraits en attente',
      'economySettings': 'Paramètres économiques',
      'couldNotLoadPrice': 'Impossible de charger le prix du jeton : {error}',
      'couldNotLoadPrice.money': 'Impossible de charger le taux : {error}',
      'quantity': 'Quantité',
      'quantity.money': 'Montant (Ar)',
      'paymentProvider': 'Opérateur de paiement',
      'payInstructions':
          'Payez {amount} au {phone} depuis votre application mobile money.',
      'yourPhoneNumber': 'Votre numéro de téléphone',
      'transactionRef': 'Référence de la transaction',
      'transactionRefHint': 'Réf ou Trans Id de votre SMS',
      'submitPayment': 'J’ai payé',
      'waitingForConfirmation': 'En attente de la confirmation du paiement...',
      'chipsCredited': 'Jetons crédités sur votre portefeuille !',
      'chipsCredited.money': 'Dépôt crédité sur votre portefeuille !',
      'couldNotBuyChips': "Impossible d'envoyer le paiement : {error}",
      'payoutPhoneNumber': 'Numéro de paiement',
      'redeemTotalLine': 'Vous recevrez {amount} Ar',
      'submitRedemption': 'Encaisser',
      'submitRedemption.money': 'Retirer',
      'waitingForPayout': 'En attente de la confirmation du paiement...',
      'redemptionPaidOut': 'Encaissement payé !',
      'redemptionPaidOut.money': 'Retrait payé !',
      'redemptionCancelled':
          'Encaissement annulé - vos jetons ont été remboursés.',
      'redemptionCancelled.money':
          'Retrait annulé - votre solde a été recrédité.',
      'couldNotRedeemChips':
          "Impossible d'envoyer la demande d'encaissement : {error}",
      'couldNotRedeemChips.money':
          "Impossible d'envoyer la demande de retrait : {error}",
      'chipPriceField': 'Prix du jeton (Ar par jeton)',
      'savePrice': 'Enregistrer le prix',
      'priceUpdated': 'Prix mis à jour',
      'couldNotUpdatePrice': 'Impossible de mettre à jour le prix : {error}',
      'sellSpreadPercentField': 'Écart à la vente',
      'rakePercentField': 'Commission de table',
      'rakeMinField': 'Commission minimale',
      'houseReceivingPhoneNumberField': 'Numéro de réception de la maison',
      'saveConfig': 'Enregistrer la config',
      'configUpdated': 'Config mise à jour',
      'couldNotUpdateConfig': 'Impossible de mettre à jour la config : {error}',
      'pendingRedemptionsSubtitle':
          'Jetons déjà brûlés, paiement encore dû. Envoyez-les à la main.',
      'noPendingRedemptions': 'Aucun encaissement en attente.',
      'couldNotLoadPendingRedemptions':
          'Impossible de charger les encaissements en attente : {error}',
      'cancelRedemptionTitle': 'Annuler cet encaissement ?',
      'cancelRedemptionContent': 'Les jetons du joueur seront remboursés.',
      'cancelRedemptionButton': "Annuler l'encaissement",
      'couldNotCancelRedemption':
          "Impossible d'annuler l'encaissement : {error}",
      'settings': 'Paramètres',
      'settingsGeneral': 'Général',
      'settingsAccount': 'Compte',
      'settingsTable': 'Table',
      'chipsAsMoney': 'Afficher les jetons en argent',
      'chipsAsMoneySubtitle':
          'Affiche chaque compte de jetons en Ariary. C\'est votre propre valorisation, pas un taux officiel.',
      'chipsAsMoneyExample': "{chips} jetons s'affichent comme {money}",
      'tableSounds': 'Sons de la table',
      'tableSoundsSubtitle':
          'Sons des cartes, des jetons et des boutons pendant une main.',
      'paymentPhoneNumber': 'Numéro de téléphone de paiement',
      'paymentPhoneNumberSubtitle':
          'Sert à payer les jetons que vous achetez et à recevoir le paiement de ceux que vous vendez.',
      'phoneNumberNotSet': 'Pas encore renseigné',
      'savePhoneNumber': 'Enregistrer le numéro',
      'phoneNumberSaved': 'Numéro enregistré',
      'couldNotLoadPhoneNumber': 'Impossible de charger votre numéro : {error}',
      'couldNotSavePhoneNumber':
          "Impossible d'enregistrer votre numéro : {error}",
      'back': 'Retour',
      'usernameHint': 'Votre nom de table',
      'passwordHint': 'Au moins 8 caractères',
      'showPassword': 'Afficher le mot de passe',
      'loginSubtitle': 'Bon retour.',
      'alreadyHaveAnAccount': 'Vous avez déjà un compte ?',
      'newHere': 'Nouveau ici ?',
      'tableLink': 'Lien de la table',
      'balance': 'Solde',
      'atTables': 'Aux tables',
      'deposit': 'Dépôt',
      'withdraw': 'Retrait',
      'seatsOpen': 'Places libres',
      'table': 'Table',
      'bigBlindsPreset': '{count} BB',
      'maxPreset': 'Max',
      'thatsNBigBlinds': 'Soit {count} grosses blindes.',
      'balanceOf': 'Solde : {amount}',
      'house': 'La maison',
      'admin': 'Admin',
      'refresh': 'Actualiser',
      'pendingRedemptionsHint': 'Paiements que vous devez encore aux joueurs',
      'economySettingsHint': 'Prix du jeton, écart et commission',
      'chipsYouGet': 'Jetons reçus',
      'fee': 'Frais',
      'youPay': 'Vous payez',
      'sendThePayment': 'Envoyez le paiement',
      'confirmItHere': 'Confirmez-le ici',
      'copyNumber': 'Copier le numéro',
      'numberCopied': 'Numéro copié',
      'depositSubtitle': 'Rechargez avec le mobile money.',
      'withdrawSubtitle': 'Renvoyez votre solde vers le mobile money.',
      'allPreset': 'Tout',
      'chipsBurned': 'Jetons brûlés',
      'youWillReceive': 'Vous recevrez',
      'payoutsByHand':
          'Les paiements sont envoyés à la main, généralement sous un jour.',
      'owedInTotal': 'Dû au total',
      'toSend': 'À envoyer',
      'nPending': '{count} en attente',
      'chipPrice': 'Prix du jeton',
      'price': 'Prix',
      'arPerChip': 'Ar par jeton',
      'fees': 'Frais',
      'houseAccount': 'Compte de la maison',
      'receivingPhoneNumber': 'Numéro de réception',
      'noMinimum': 'Pas de minimum',
      'winner': 'Gagnant',
      'yourTurnBadge': 'À vous',
      'handStrength': 'Force de la main',
      'sendReaction': 'Envoyer une réaction',
      'betAmount': 'Montant de la mise',
      'tablePausedHost':
          'Vous avez mis cette table en pause. Personne ne peut jouer avant que vous la repreniez.',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
