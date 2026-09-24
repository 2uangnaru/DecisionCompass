import 'dart:async';

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../category_presentation.dart';
import '../data/daily_energy_insight_deck.dart';
import '../data/models/models.dart' as engine;
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import '../widgets/daily_energy_info.dart';
import '../widgets/responsible_use_sheet.dart';
import 'history_page.dart';
import 'ritual_page.dart';

const _shortMonths = <String>[
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

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

  /// Today's rotating description, once the saved deck has been read. Null
  /// means "not resolved yet"; the copy block holds its space rather than
  /// showing another day's line for a frame.
  String? _description;

  /// The local day [_description] belongs to. A load that started on an
  /// earlier day is discarded when it lands, so a slow store cannot drop
  /// yesterday's line onto today.
  String? _descriptionDay;

  static String _dayKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _briefLocalDay = _dayKey(widget.dependencies.nowLocal());
    _dailyBrief = widget.dependencies.dailyBriefProvider.preview(_profile);
    _loadDescription();
    _scheduleDayChange();
  }

  /// Deals (or re-reads) the description for the local day now showing.
  Future<void> _loadDescription() async {
    final local = widget.dependencies.nowLocal();
    final day = _dayKey(local);
    if (_descriptionDay != day) {
      // Yesterday's line must not sit on screen while the deck answers for
      // today. `initState` reaches here with nothing shown yet, so there is
      // no setState before the first build.
      _descriptionDay = day;
      if (_description != null) setState(() => _description = null);
    }

    final description = await widget.dependencies.homeDescriptionDeck
        .descriptionFor(local);
    if (!mounted || _descriptionDay != day) return;
    setState(() => _description = description);
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
      // Only on a genuinely new day: resuming on the same date must leave the
      // description exactly as it was.
      _loadDescription();
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
            const SizedBox(height: 22),
            // No heading here: the positioning copy above already asks for
            // this, and a second one made the screen read as a wall of
            // headings.
            _modeGrid(),
            const SizedBox(height: 28),
            Text(
              'What area is this about?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            _categorySelector(),
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
        // Roughly three lines at this style on a 360dp phone. Holding that
        // space stops the block from jumping once the saved deck has been
        // read, without ever rendering the wrong day's line.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 63),
          child: Text(
            _description ?? '',
            key: const Key('home_description'),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.5),
          ),
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
    final today = widget.dependencies.nowLocal();
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TODAY’S SIGNALS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CompassColors.gold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              Text(
                '${_shortMonths[today.month - 1]} ${today.day}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CompassColors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<engine.DailyBrief?>(
            key: const Key('daily_signals_content'),
            future: _dailyBrief,
            builder: (context, snapshot) {
              final brief = snapshot.data;
              final colors = brief?.colors;
              final energy = brief?.energy;
              final energyAccent = switch (energy?.level) {
                'quiet' || 'soft' => CompassColors.blueLight,
                'steady' => CompassColors.teal,
                'lively' || 'focused' => CompassColors.teal,
                'flowing' => CompassColors.violet,
                'bright' || 'radiant' => CompassColors.gold,
                _ => CompassColors.muted,
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily energy',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: CompassColors.secondary,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    energy?.displayLabel ?? '—',
                                    key: const Key('daily_energy_label'),
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: CompassColors.text,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                // Home always speaks for the current local
                                // day, and is where discovery lives.
                                DailyEnergyInfoButton(
                                  level: energy?.level,
                                  controller:
                                      widget.dependencies.dailyEnergyInsights,
                                  day: dailyEnergyDayKey(
                                    widget.dependencies.nowLocal(),
                                  ),
                                  showsDiscovery: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: energyAccent.withValues(alpha: 0.12),
                          border: Border.all(
                            color: energyAccent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 17,
                          color: energyAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _TodaySignalTile(
                            label: 'Your colors today:',
                            // Equal-width columns keep both colours on one
                            // baseline, even in the half-width signal tile.
                            value: Row(
                              children: [
                                Expanded(
                                  child: _Swatch(
                                    color: colors?.lead,
                                    role: 'Lead',
                                    testKey: 'daily_color_lead',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _Swatch(
                                    color: colors?.supporting,
                                    role: 'Supporting',
                                    testKey: 'daily_color_supporting',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TodaySignalTile(
                            label: 'Lucky number today:',
                            value: Text(
                              brief?.luckyNumber.toString() ?? '—',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: brief == null
                                    ? CompassColors.text
                                    : CompassColors.blueLight,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                shadows: brief == null
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: CompassColors.blueLight
                                              .withValues(alpha: 0.45),
                                          blurRadius: 16,
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _TodaySignalTile extends StatelessWidget {
  const _TodaySignalTile({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CompassColors.line.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: CompassColors.secondary, fontSize: 11),
          ),
          const SizedBox(height: 3),
          // Only the value is centred; the label stays where it was.
          Center(child: value),
        ],
      ),
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

/// One of the day's two colours: the swatch, its name, and the role it plays.
/// The hex is the engine's; the app only draws it.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.role,
    required this.testKey,
  });

  final engine.DailyColor? color;
  final String role;
  final String testKey;

  @override
  Widget build(BuildContext context) {
    final swatch = color == null ? CompassColors.line : Color(color!.argb);
    return Semantics(
      label: color == null
          ? '$role colour not available yet'
          : '$role colour, ${color!.name}',
      child: Column(
        key: Key(testKey),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: swatch,
              border: Border.all(color: Colors.white54, width: 1.2),
              boxShadow: color == null
                  ? null
                  : [
                      BoxShadow(
                        color: swatch.withValues(alpha: 0.5),
                        blurRadius: 9,
                        spreadRadius: 0.5,
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            color?.name ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CompassColors.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
