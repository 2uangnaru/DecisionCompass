import 'package:flutter/material.dart';

import '../theme.dart';

/// Copy for the one energy label shown on the user's current local day.
const _energyMessages = <String, ({String label, String message})>{
  'quiet': (
    label: 'QUIET',
    message: 'Today’s symbolic energy turns inward, making space for quiet reflection.',
  ),
  'soft': (
    label: 'SOFT',
    message: 'Today’s symbolic energy moves gently, with room for care and small steps.',
  ),
  'steady': (
    label: 'STEADY',
    message: 'Today’s symbolic energy keeps an even, grounded rhythm.',
  ),
  'lively': (
    label: 'LIVELY',
    message: 'A playful spark stirs today’s symbolic energy, bringing curiosity and motion.',
  ),
  'bright': (
    label: 'BRIGHT',
    message:
        'Today’s symbolic energy shines with momentum and room for expression.',
  ),
  'radiant': (
    label: 'RADIANT',
    message:
        'Today’s symbolic energy reaches its fullest glow: open and expansive.',
  ),
  'focused': (
    label: 'FOCUSED',
    message: 'Today’s symbolic energy gathers around a clear direction; the action signal takes the lead.',
  ),
  'flowing': (
    label: 'FLOWING',
    message: 'Today’s symbolic energy moves with the tide; the change signal takes the lead.',
  ),
};

class DailyEnergyInfoButton extends StatelessWidget {
  const DailyEnergyInfoButton({super.key, required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('daily_energy_info_button'),
      tooltip: 'What does today’s energy mean?',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _DailyEnergyInfoSheet(level: level),
      ),
      icon: const Icon(Icons.info_outline_rounded, size: 18),
      color: CompassColors.muted,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _DailyEnergyInfoSheet extends StatelessWidget {
  const _DailyEnergyInfoSheet({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final message =
        _energyMessages[level] ??
        (
          label: 'UNAVAILABLE',
          message: 'There isn’t enough information to describe today’s symbolic energy.',
        );

    return Container(
      key: const Key('daily_energy_info_sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: CompassColors.raised,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: CompassColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'TODAY’S ENERGY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: CompassColors.gold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: CompassColors.muted,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                message.label,
                key: const Key('daily_energy_info_label'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: CompassColors.text,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                message.message,
                key: const Key('daily_energy_info_message'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CompassColors.secondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: CompassColors.line),
              const SizedBox(height: 13),
              const Text(
                'A symbolic reflection, not a measure of mood, health, or what will happen.',
                style: TextStyle(
                  color: CompassColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
