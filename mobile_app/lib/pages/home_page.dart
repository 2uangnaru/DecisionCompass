import 'dart:async';

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../category_presentation.dart';
import '../data/models/models.dart' as engine;
import '../models.dart';
import '../reading_dependencies.dart';
import '../text_formatting.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import '../widgets/responsible_use_sheet.dart';
import 'history_page.dart';
import 'ritual_page.dart';

/// Exhaustive per the engine's fixed `COLORS` list
/// (`calculation-engine/src/index.js`), but looked up rather than
/// switched-on: a plain string is tolerant of a value this map does not yet
/// know, falling back to a neutral swatch instead of crashing.
const _colorSwatches = <String, Color>{
  'sage': Color(0xFF8FA989),
  'coral': Color(0xFFD97B69),
  'sand': Color(0xFFD9C29A),
  'pearl': Color(0xFFE8E3DA),
  'ocean_blue': CompassColors.blueLight,
};

/// Buckets a real wall-clock hour into the three greetings the design uses.
/// There is no "good night" bucket: the app's own copy never implies the user
/// should be asleep.
String _greeting(DateTime local) {
  final hour = local.hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 18) return 'Good afternoon,';
  return 'Good evening,';
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.dependencies,
  });

  final AppProfile profile;
  final ReadingDependencies dependencies;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  DecisionMode _mode = DecisionMode.yesNo;

  /// Overall is the default; the typed enum travels the whole flow, never a
  /// raw wire string.
  engine.ReadingCategory _category = engine.ReadingCategory.general;

  late AppProfile _profile = widget.profile;

  /// Ambient preview, refreshed when the device's local calendar day changes.
  /// It never enters reading history; an actual Reveal has its own snapshot.
  late Future<engine.DailyBrief?> _dailyBrief;
  late String _briefLocalDay;
  Timer? _dayChangeTimer;

  static String _dayKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _briefLocalDay = _dayKey(widget.dependencies.nowLocal());
    _dailyBrief = widget.dependencies.dailyBriefProvider.preview(_profile);
    _scheduleDayChange();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshIfNewDay();
  }

  void _refreshIfNewDay() {
    final local = widget.dependencies.nowLocal();
    final day = _dayKey(local);
    if (day != _briefLocalDay) {
      setState(() {
        _briefLocalDay = day;
        _dailyBrief = widget.dependencies.dailyBriefProvider.preview(_profile);
      });
    }
    _scheduleDayChange();
  }

  void _scheduleDayChange() {
    _dayChangeTimer?.cancel();
    final local = widget.dependencies.nowLocal();
    final next = DateTime(local.year, local.month, local.day + 1);
    final remaining = next.difference(local);
    _dayChangeTimer = Timer(
      remaining > Duration.zero ? remaining : const Duration(seconds: 1),
      () {
        if (mounted) _refreshIfNewDay();
      },
    );
  }

  @override
  void dispose() {
    _dayChangeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _beginReading() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RitualPage(
          mode: _mode,
          // When is chosen on the ritual screen, next to the moment the user
          // actually taps Reveal. NOW is where that selector opens.
          period: TimePeriod.now,
          category: _category,
          profile: _profile,
          dependencies: widget.dependencies,
          onSafetyAcknowledged: (updated) {
            setState(() => _profile = updated);
            widget.dependencies.profileRepository.save(updated);
          },
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
            _positioning(),
            const SizedBox(height: 26),
            Text(
              'What area is this about?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            _categorySelector(),
            const SizedBox(height: 28),
            Text(
              'Which direction do you need?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            _modeGrid(),
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
                '${categoryLabel(_category)}  •  ${_mode.label}',
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
        ZodiacAvatar(size: 52, sign: widget.profile.zodiacSign),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(widget.dependencies.nowLocal()),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                widget.profile.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          key: const Key('home_responsible_use_button'),
          tooltip: 'Responsible Use',
          onPressed: () => showResponsibleUseSheet(context),
          icon: const Icon(Icons.shield_outlined, size: 20),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'History',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HistoryPage(dependencies: widget.dependencies),
            ),
          ),
          icon: const Icon(Icons.history_rounded),
        ),
      ],
    );
  }

  /// Says plainly what the app is for, without promising certainty.
  Widget _positioning() {
    return Column(
      key: const Key('home_positioning'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A compass for uncertain moments'.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: CompassColors.gold, letterSpacing: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          'Caught between choices?',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose what’s on your mind and the moment you’re considering. '
          'We’ll read today’s symbolic patterns and offer a direction—not a '
          'command.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
  }

  /// Android's minimum accessible touch target. The card's padding plus its
  /// icon/label line only reach ~39dp, so the height is constrained explicitly
  /// rather than by inflating the padding.
  static const double _minTouchTarget = 48;

  /// Wrapping compact cards: seven choices stay reachable on a 360dp phone
  /// without pushing the decision modes off the first screenful.
  Widget _categorySelector() {
    return Wrap(
      key: const Key('category_selector'),
      spacing: 8,
      runSpacing: 8,
      children: categoryChoices.map((choice) {
        final selected = choice.category == _category;
        return Semantics(
          button: true,
          selected: selected,
          label: choice.label,
          child: ConstrainedBox(
            // The constraint reaches Material and InkWell unchanged, so the
            // whole tappable area is 48dp tall, not just the painted box.
            constraints: const BoxConstraints(minHeight: _minTouchTarget),
            child: GlassCard(
              key: Key(choice.testKey),
              selected: selected,
              onTap: () => setState(() => _category = choice.category),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    choice.icon,
                    size: 17,
                    color: selected
                        ? CompassColors.blueLight
                        : CompassColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    choice.label,
                    style: TextStyle(
                      color: selected
                          ? CompassColors.blueLight
                          : CompassColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
          FutureBuilder<engine.DailyBrief?>(
            key: const Key('daily_signals_content'),
            future: _dailyBrief,
            builder: (context, snapshot) {
              final brief = snapshot.data;
              final colorName = brief?.colorInspiration;
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorName == null
                              ? CompassColors.line
                              : (_colorSwatches[colorName] ??
                                    CompassColors.blueLight),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Signal(
                          label: 'Your color',
                          value: colorName == null
                              ? '—'
                              : titleCaseWords(colorName),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Signal(
                        label: 'Lucky number',
                        value: brief?.luckyNumber.toString() ?? '—',
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: CompassColors.line),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily energy',
                        style: TextStyle(color: CompassColors.secondary),
                      ),
                      Text(
                        brief?.energy?.displayLabel ?? '—',
                        key: const Key('daily_energy_label'),
                        style: const TextStyle(
                          color: CompassColors.teal,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
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
