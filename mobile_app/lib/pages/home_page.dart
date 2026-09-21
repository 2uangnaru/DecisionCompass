import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import 'history_page.dart';
import 'ritual_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.userName, required this.zodiacSign});

  final String userName;
  final ZodiacSign zodiacSign;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DecisionMode _mode = DecisionMode.yesNo;
  TimePeriod _period = TimePeriod.now;

  void _beginReading() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RitualPage(
          mode: _mode,
          period: _period,
          zodiacSign: widget.zodiacSign,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CelestialScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 24),
            _dailySignals(),
            const SizedBox(height: 28),
            Text(
              'A choice is on your mind.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose the direction you need.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _modeGrid(),
            const SizedBox(height: 28),
            Text(
              'When are you considering it?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            _timeSelector(),
            const SizedBox(height: 28),
            FilledButton.icon(
              key: const Key('find_direction'),
              onPressed: _beginReading,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Find My Direction'),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${_mode.label}  •  ${_period.label.toUpperCase()}  •  LOCAL TIMING',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: CompassColors.muted, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        ZodiacAvatar(size: 52, sign: widget.zodiacSign),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good evening,',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                widget.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'History',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const HistoryPage())),
          icon: const Icon(Icons.history_rounded),
        ),
      ],
    );
  }

  Widget _dailySignals() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY’S SIGNALS',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: CompassColors.gold, letterSpacing: 1.6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [CompassColors.blueLight, CompassColors.blue],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _Signal(label: 'Your color', value: 'Ocean Blue'),
              ),
              const SizedBox(width: 10),
              const _Signal(label: 'Lucky number', value: '7'),
            ],
          ),
          const Divider(height: 28, color: CompassColors.line),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily energy',
                style: TextStyle(color: CompassColors.secondary),
              ),
              Text(
                'STEADY',
                style: TextStyle(color: CompassColors.teal, letterSpacing: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeGrid() {
    Widget card(DecisionMode mode) => _ModeCard(
      mode: mode,
      selected: _mode == mode,
      onTap: () => setState(() => _mode = mode),
    );

    return Column(
      children: [
        card(DecisionMode.yesNo),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: card(DecisionMode.stayGo)),
            const SizedBox(width: 10),
            Expanded(child: card(DecisionMode.actWait)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: card(DecisionMode.forwardBackward)),
            const SizedBox(width: 10),
            Expanded(child: card(DecisionMode.leftRight)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: card(DecisionMode.keepLetGo)),
            const SizedBox(width: 10),
            Expanded(child: card(DecisionMode.advanceRetreat)),
          ],
        ),
      ],
    );
  }

  Widget _timeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TimePeriod.values.map((period) {
          final selected = period == _period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: Key('period_${period.name}'),
              label: Text(period.label),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _period = period),
              selectedColor: const Color(0xFF244C78),
              side: BorderSide(
                color: selected ? CompassColors.blueLight : CompassColors.line,
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : CompassColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Signal extends StatelessWidget {
  const _Signal({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final DecisionMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              mode.first,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: selected ? CompassColors.blueLight : CompassColors.text,
                fontWeight: FontWeight.w700,
                fontSize:
                    mode == DecisionMode.advanceRetreat ||
                        mode == DecisionMode.forwardBackward
                    ? 10
                    : 13,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 7),
            child: Text('/', style: TextStyle(color: CompassColors.muted)),
          ),
          Flexible(
            child: Text(
              mode.second,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: selected
                    ? CompassColors.blueLight
                    : CompassColors.secondary,
                fontWeight: FontWeight.w700,
                fontSize:
                    mode == DecisionMode.advanceRetreat ||
                        mode == DecisionMode.forwardBackward
                    ? 10
                    : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
