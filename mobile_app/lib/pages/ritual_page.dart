import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../category_presentation.dart';
import '../data/models/models.dart' as engine;
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import '../widgets/responsible_use_sheet.dart';
import 'loading_page.dart';

class RitualPage extends StatefulWidget {
  const RitualPage({
    super.key,
    required this.mode,
    required this.period,
    required this.category,
    required this.profile,
    required this.dependencies,
    this.onSafetyAcknowledged,
  });

  final DecisionMode mode;
  final TimePeriod period;
  final engine.ReadingCategory category;
  final AppProfile profile;
  final ReadingDependencies dependencies;
  final ValueChanged<AppProfile>? onSafetyAcknowledged;

  @override
  State<RitualPage> createState() => _RitualPageState();
}

class _RitualPageState extends State<RitualPage>
    with SingleTickerProviderStateMixin {
  var _locked = false;
  Timer? _periodRefreshTimer;
  late final AnimationController _pulseController;
  late AppProfile _profile = widget.profile;

  /// When the reading is for. Chosen here, beside the Reveal tap, so the
  /// moment and the period are picked together.
  late TimePeriod _period = widget.period;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _schedulePeriodRefresh();
  }

  @override
  void dispose() {
    _periodRefreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Refresh the chips as soon as a period ends, even if the user leaves this
  /// screen open without touching it. Midnight also resets the day's chips.
  void _schedulePeriodRefresh() {
    _periodRefreshTimer?.cancel();
    final now = widget.dependencies.nowLocal();
    final boundaries = [
      DateTime(now.year, now.month, now.day, 12),
      DateTime(now.year, now.month, now.day, 14),
      DateTime(now.year, now.month, now.day, 18),
      DateTime(now.year, now.month, now.day + 1),
    ];
    final next = boundaries.firstWhere((boundary) => boundary.isAfter(now));
    _periodRefreshTimer = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _schedulePeriodRefresh();
    });
  }

  bool _rejectElapsedPeriod() {
    if (!_period.hasElapsedAt(widget.dependencies.nowLocal())) return false;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_period.label} has passed. Choose another time.'),
      ),
    );
    return true;
  }

  Future<void> _reveal() async {
    if (_locked) return;
    if (_rejectElapsedPeriod()) return;
    if (!_profile.safetyAcknowledged) {
      final agreed = await showResponsibleUseSheet(
        context,
        isFirstTimeAcknowledgement: true,
      );
      if (!agreed || !mounted) return;
      setState(() => _profile = _profile.copyWith(safetyAcknowledged: true));
      widget.onSafetyAcknowledged?.call(_profile);
    }
    if (_rejectElapsedPeriod()) return;
    setState(() => _locked = true);
    // The reading's moment is this tap, recorded before the transition and
    // before any timezone or GPS lookup, so a slow lookup cannot move it.
    final instantUtc = widget.dependencies.nowUtc();
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoadingPage(
          mode: widget.mode,
          period: _period,
          category: widget.category,
          profile: _profile,
          instantUtc: instantUtc,
          dependencies: widget.dependencies,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return CelestialScaffold(
      // One hierarchy, top to bottom: what the reading is about, when it is
      // for, the control itself, then the words that frame it. The reveal
      // circle takes whatever height is left over and centres inside it, so
      // there is no fixed gap to grow large on a tall screen. When the screen
      // is too short — or the text scale too large — the whole thing scrolls
      // rather than overflowing.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          // Sized from the space actually available rather than from a
          // breakpoint, and capped by width so it never crowds the edges.
          final ringSize = math.min(
            (constraints.maxHeight * 0.28).clamp(150.0, 220.0),
            constraints.maxWidth * 0.62,
          );
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              compact ? 6 : 12,
              20,
              compact ? 18 : 28,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (compact ? 24 : 40),
              ),
              child: IntrinsicHeight(
                child: _body(compact, ringSize, ringSize * 0.81, reduceMotion),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(
    bool compact,
    double ringSize,
    double buttonSize,
    bool reduceMotion,
  ) {
    final selectedPeriodElapsed = _period.hasElapsedAt(
      widget.dependencies.nowLocal(),
    );
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _locked ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            Expanded(
              child: Text(
                widget.mode.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: CompassColors.gold, letterSpacing: 1.8),
              ),
            ),
            IconButton(
              key: const Key('ritual_responsible_use_button'),
              tooltip: 'Responsible Use',
              onPressed: _locked
                  ? null
                  : () => showResponsibleUseSheet(context),
              icon: const Icon(Icons.shield_outlined, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CategoryBadge(
          key: const Key('ritual_category_badge'),
          label: categoryLabel(widget.category),
        ),
        SizedBox(height: compact ? 10 : 18),
        _periodSelector(),
        // The circle takes the leftover height and centres in it, so the
        // slack is shared above and below instead of piling up above.
        Expanded(
          child: Center(
            child: Semantics(
              button: true,
              enabled: !_locked && !selectedPeriodElapsed,
              label:
                  'Reveal my direction for ${_period.whenPhrase.toLowerCase()}, '
                  '${widget.mode.label}',
              child: GestureDetector(
                key: const Key('reveal_button'),
                onTap: _locked || selectedPeriodElapsed ? null : _reveal,
                child: Opacity(
                  opacity: selectedPeriodElapsed ? 0.45 : 1,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulse = reduceMotion || selectedPeriodElapsed
                          ? 0.0
                          : _pulseController.value;
                      // Outer ring breathes noticeably wider than the core button
                      // so the pulse reads clearly without the whole control
                      // feeling like it is jumping in size.
                      final ringScale = _locked ? 0.96 : 1 + pulse * 0.09;
                      final coreScale = _locked ? 0.96 : 1 + pulse * 0.022;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: ringScale,
                            child: Container(
                              width: ringSize,
                              height: ringSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CompassColors.blueLight.withValues(
                                    alpha: 0.2 + pulse * 0.28,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CompassColors.blueLight.withValues(
                                      alpha: 0.08 + pulse * 0.1,
                                    ),
                                    blurRadius: 24 + pulse * 26,
                                    spreadRadius: pulse * 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: coreScale,
                            child: Container(
                              width: buttonSize,
                              height: buttonSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF286DA5),
                                    Color(0xFF153553),
                                  ],
                                ),
                                border: Border.all(
                                  color: CompassColors.blueLight,
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CompassColors.blueLight.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: _locked ? 48 : 30 + pulse * 12,
                                    spreadRadius: _locked ? 8 : 2 + pulse * 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ZodiacAvatar(
                                    size: compact ? 54 : 62,
                                    sign: widget.profile.zodiacSign,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _locked
                                        ? 'ALIGNING'
                                        : selectedPeriodElapsed
                                        ? 'PASSED'
                                        : 'REVEAL',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 16 : 26),
        Text(
          _locked
              ? 'Your moment is locked.'
              : selectedPeriodElapsed
              ? '${_period.label} has passed. Choose another time.'
              : 'Tap when you’re ready',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Keep the choice clearly in your mind.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: compact ? 10 : 14),
        // Readable rather than fine print, and the last thing on the screen:
        // the badge above already names the area and the chips the time, so
        // the old "Reading for X · Y" footer only repeated them.
        Text(
          'For everyday reflection only • Never for medical, financial, '
          'political, or harmful choices.',
          key: const Key('ritual_responsible_use_note'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: CompassColors.secondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  /// Compact chips, wrapped and centred so all five fit a 360dp phone without
  /// overflow and without competing with the reveal circle for attention.
  Widget _periodSelector() {
    // Read on every build so a period that ends while the screen is open stops
    // being offered. The engine's own `period_elapsed` answer stays the
    // authority if the clock crosses the boundary after the tap.
    final localNow = widget.dependencies.nowLocal();
    return Column(
      children: [
        Text(
          'When are you considering it?',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: CompassColors.secondary, letterSpacing: 0.7),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('ritual_period_selector'),
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 2,
          children: TimePeriod.values.map((period) {
            final elapsed = period.hasElapsedAt(localNow);
            final selected = period == _period;
            return ChoiceChip(
              key: Key('ritual_period_${period.name}'),
              label: Text(elapsed ? '${period.label} · Passed' : period.label),
              selected: selected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              // A null callback is what disables a chip. Elapsed periods stay
              // on screen, muted, so the whole day is still legible.
              onSelected: elapsed || _locked
                  ? null
                  : (_) {
                      // A boundary may have passed since the last paint.
                      if (period.hasElapsedAt(widget.dependencies.nowLocal())) {
                        setState(() {});
                        return;
                      }
                      setState(() => _period = period);
                    },
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              disabledColor: Colors.white.withValues(alpha: 0.02),
              selectedColor: const Color(0xFF244C78),
              side: BorderSide(
                color: selected && !elapsed
                    ? CompassColors.blueLight
                    : CompassColors.line,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: elapsed
                    ? CompassColors.muted
                    : selected
                    ? Colors.white
                    : CompassColors.secondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Compact, calm badge naming the area the reading concerns.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Reading area: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CompassColors.line),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: CompassColors.blueLight, letterSpacing: 0.9),
        ),
      ),
    );
  }
}
