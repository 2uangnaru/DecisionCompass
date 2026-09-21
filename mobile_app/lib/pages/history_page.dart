import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/celestial_ui.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CelestialScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Text(
                  'Your readings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'TODAY',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: CompassColors.gold, letterSpacing: 1.7),
            ),
            const SizedBox(height: 12),
            const _HistoryRow(
              mode: 'YES / NO',
              result: 'YES 64%',
              period: 'NOW',
              time: '8:42 PM',
            ),
            const SizedBox(height: 10),
            const _HistoryRow(
              mode: 'STAY / GO',
              result: 'GO 58%',
              period: 'EVENING',
              time: '7:10 PM',
            ),
            const Spacer(),
            Center(
              child: Text(
                'Results are saved as snapshots and never rerolled.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: CompassColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.mode,
    required this.result,
    required this.period,
    required this.time,
  });

  final String mode;
  final String result;
  final String period;
  final String time;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '$period  •  $time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            result,
            style: const TextStyle(
              color: CompassColors.blueLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: CompassColors.muted),
        ],
      ),
    );
  }
}
