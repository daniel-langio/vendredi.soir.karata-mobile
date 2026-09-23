import 'package:flutter/material.dart';
import '../../icons/dealer_button_icon.dart';

/// The floating "D" marker placed at the dealer's seat (or over the hero's hand row when the
/// hero is the dealer).
class DealerChip extends StatelessWidget {
  const DealerChip({super.key});

  @override
  Widget build(BuildContext context) => const DealerButtonIcon(size: 18);
}
