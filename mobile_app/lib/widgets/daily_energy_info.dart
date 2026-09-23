import 'package:flutter/material.dart';

import '../theme.dart';

/// One sentence per tone, for the single energy label shown on the user's
/// current local day. There is deliberately no entry for `unavailable`: a day
/// without an energy reading has nothing to explain, so the button is hidden
/// rather than shown with an apology.
const _energyMessages = <String, String>{
  'quiet': 'Today’s symbolic energy turns inward, making space for quiet reflection.',
  'soft': 'Today’s symbolic energy moves gently, with room for care and small steps.',
  'steady': 'Today’s symbolic energy keeps an even, grounded rhythm.',
  'lively': 'A playful spark stirs today’s symbolic energy, bringing curiosity and motion.',
  'bright':
      'Today’s symbolic energy shines with momentum and room for expression.',
  'radiant':
      'Today’s symbolic energy reaches its fullest glow: open and expansive.',
  'focused':
      'Today’s symbolic energy gathers around a clear direction; the action '
      'signal takes the lead.',
  'flowing':
      'Today’s symbolic energy moves with the tide; the change signal takes '
      'the lead.',
};

/// The sentence describing [level], or null when there is nothing to say —
/// no brief yet, or a level this build does not have copy for. Callers use
/// null to decide whether the ⓘ button appears at all.
String? dailyEnergyMessage(String? level) =>
    level == null ? null : _energyMessages[level];

/// The grey ⓘ that reveals [DailyEnergyNote] in place. It opens nothing: no
/// sheet, dialog or overlay, so the card the user is already reading simply
/// grows by one line.
class DailyEnergyInfoButton extends StatelessWidget {
  const DailyEnergyInfoButton({
    super.key,
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('daily_energy_info_button'),
      tooltip: expanded
          ? 'Hide what today’s energy means'
          : 'What does today’s energy mean?',
      onPressed: onPressed,
      icon: Icon(
        expanded ? Icons.info_rounded : Icons.info_outline_rounded,
        size: 18,
      ),
      color: expanded ? CompassColors.secondary : CompassColors.muted,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

/// The one-line explanation, directly under the label it describes.
///
/// It always reads [level] from the brief currently on screen, so a new local
/// day swaps the sentence without the reader having to close and reopen it.
class DailyEnergyNote extends StatelessWidget {
  const DailyEnergyNote({
    super.key,
    required this.level,
    required this.visible,
  });

  final String? level;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final message = dailyEnergyMessage(level);
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: visible && message != null
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              // Full width so the sentence reads from the left edge whatever
              // the surrounding column aligns its children to.
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  message,
                  key: const Key('daily_energy_note'),
                  style: const TextStyle(
                    color: CompassColors.secondary,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
