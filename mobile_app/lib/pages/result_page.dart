import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.result});

  final ReadingResult result;

  @override
  Widget build(BuildContext context) {
    final isCaution = result.winner == 'NO' || result.winner == 'LET GO';
    return CelestialScaffold(
      topColor: isCaution ? const Color(0xFF1A1018) : const Color(0xFF071729),
      bottomColor: isCaution
          ? const Color(0xFF552D36)
          : const Color(0xFF103B68),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Text(
                    result.mode.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: CompassColors.gold,
                      letterSpacing: 1.7,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              'YOUR DIRECTION',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Colors.white70, letterSpacing: 2.4),
            ),
            const SizedBox(height: 20),
            Text(
              result.winner,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${result.winnerPercent}%',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(color: CompassColors.blueLight, fontSize: 42),
            ),
            const SizedBox(height: 14),
            Text(
              '${result.counterpart}  ${result.counterpartPercent}%',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(result.alignment),
            ),
            const SizedBox(height: 18),
            Text(
              'Based on your personal cycles and this moment.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 30),
            if (result.period == TimePeriod.now)
              const GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: CompassColors.gold),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('This reading reflects your current moment.'),
                    ),
                  ],
                ),
              )
            else
              _LuckyWindows(result: result),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Try Another Direction'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.bookmark_added_rounded),
              label: const Text('Saved to History'),
            ),
            const SizedBox(height: 22),
            Text(
              'For everyday reflection only. Important decisions need real information and qualified help.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.white60, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuckyWindows extends StatelessWidget {
  const _LuckyWindows({required this.result});

  final ReadingResult result;

  @override
  Widget build(BuildContext context) {
    final periodName = result.period.label;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Luckiest Times This $periodName',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ...result.windows.map(
            (window) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: CompassColors.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(window.time)),
                    Text(
                      '${window.score}%',
                      style: const TextStyle(
                        color: CompassColors.blueLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            'Window scores are independent and do not add up to 100%.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: CompassColors.muted),
          ),
        ],
      ),
    );
  }
}
