import 'dart:async';

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../category_presentation.dart';
import '../data/daily_energy_insight_deck.dart';
import '../data/models/models.dart' as engine;
import '../data/profile_edit_policy.dart';
import '../l10n/app_localizations.dart';
import '../localized_presentation.dart';
import '../localized_rotation.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/celestial_ui.dart';
import '../widgets/daily_energy_capsule_bar.dart';
import '../widgets/daily_energy_info.dart';
import '../widgets/header_settings_capsule.dart';
import '../widgets/responsible_use_sheet.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'ritual_page.dart';

/// Buckets a real wall-clock hour into the three greetings the design uses.
/// There is no "good night" bucket: the app's own copy never implies the user
/// should be asleep.
String _greeting(AppLocalizations l10n, DateTime local) {
  final hour = local.hour;
  if (hour < 12) return l10n.greetingMorning;
  if (hour < 18) return l10n.greetingAfternoon;
  return l10n.greetingEvening;
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
  bool _isSettingsOpen = false;
  final GlobalKey _settingsCapsuleKey = GlobalKey();

  /// Ambient preview, refreshed when the device's local calendar day changes.
  /// It never enters reading history; an actual Reveal has its own snapshot.
  late Future<engine.DailyBrief?> _dailyBrief;

  late String _briefLocalDay;
  Timer? _dayChangeTimer;

  /// The index of today's rotating description, once the saved deck has been
  /// read. Null means "not resolved yet"; the copy block holds its space
  /// rather than showing another day's line for a frame.
  ///
  /// An index rather than the sentence: the language is resolved at build
  /// time, so switching language shows the translation of the same line
  /// without re-reading or advancing the deck.
  int? _description;

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

    final description = await widget.dependencies.homeDescriptionDeck.indexFor(
      local,
    );
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

  /// Opens Profile, and adopts whatever it saved.
  ///
  /// The page pops with the saved profile, or with null when the reader left
  /// without saving — so a cancelled edit reaches here as "nothing happened"
  /// and no part of Home is rebuilt.
  Future<void> _openProfile() async {
    final before = _profile;
    final updated = await Navigator.of(context).push<AppProfile>(
      MaterialPageRoute<AppProfile>(
        builder: (_) =>
            ProfilePage(profile: before, dependencies: widget.dependencies),
      ),
    );
    if (!mounted || updated == null) return;

    // Only the birth inputs reach the engine. A rename changes the greeting
    // and nothing else, so it must not spend a calculation — and, more to the
    // point, must not make today's colours, lucky number and energy flicker
    // through a placeholder on the way back to the same values.
    final birthChanged =
        updated.birthTime != before.birthTime ||
        updated.birthCountryCode != before.birthCountryCode ||
        !isSameBirthDate(updated.birthDate, before.birthDate);

    setState(() {
      _profile = updated;
      if (birthChanged) {
        _briefLocalDay = _dayKey(widget.dependencies.nowLocal());
        // Replacing the future is what discards a preview still in flight for
        // the old profile: `FutureBuilder` ignores a result that arrives for
        // a future it is no longer watching.
        _dailyBrief = widget.dependencies.dailyBriefProvider.preview(updated);
      }
    });
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
          isCooldown: true,
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
    final l10n = AppLocalizations.of(context);
    return CelestialScaffold(
      child: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (_isSettingsOpen) {
                  if (notification is ScrollStartNotification ||
                      notification is ScrollUpdateNotification) {
                    setState(() => _isSettingsOpen = false);
                  }
                }
                return false;
              },
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  if (_isSettingsOpen) {
                    final renderBox =
                        _settingsCapsuleKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (renderBox != null && renderBox.hasSize) {
                      final capsuleBox =
                          renderBox.localToGlobal(Offset.zero) & renderBox.size;
                      if (!capsuleBox.contains(event.position)) {
                        setState(() => _isSettingsOpen = false);
                      }
                    } else {
                      setState(() => _isSettingsOpen = false);
                    }
                  }
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(l10n),
                      const SizedBox(height: 24),
                      _dailySignals(l10n),
                      const SizedBox(height: 28),
                      _positioning(l10n),
                      const SizedBox(height: 22),
                      // No heading here: the positioning copy above already asks for
                      // this, and a second one made the screen read as a wall of
                      // headings.
                      _modeGrid(l10n),
                      const SizedBox(height: 28),
                      Text(
                        l10n.areaQuestion,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      _categorySelector(l10n),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        key: const Key('find_direction'),
                        onPressed: _beginReading,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(l10n.findDirection),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '${categoryLabel(l10n, _category)}  •  '
                          '${modeLabel(l10n, _mode)}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: CompassColors.muted,
                            letterSpacing: trackingFor(context, 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const AdBannerSlot(),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        Row(
          children: [
            // The avatar and the name are one target, not two: they read as one
            // thing, and splitting them would give a screen reader two doors into
            // the same screen.
            //
            // `_profile`, not `widget.profile`: the header used to show the
            // profile Home was *constructed* with while every calculation on the
            // same screen used the current one, so a saved edit left the greeting
            // and the avatar a step behind until the app was restarted.
            // Expanded, as the name column used to be: the greeting and the name
            // have to be free to shrink, or a long one pushes the language,
            // safety and history controls off a 360dp screen.
            Expanded(
              child: Semantics(
                button: true,
                label: l10n.openProfile,
                // The child's own node is replaced rather than merged, so a
                // screen reader hears one control and not the greeting, the name
                // and the avatar as three. Replacing it also drops the InkWell's
                // tap action, which is why the action is restated here.
                excludeSemantics: true,
                onTap: _openProfile,
                child: InkWell(
                  key: const Key('home_open_profile'),
                  onTap: _openProfile,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      ZodiacAvatar(size: 52, sign: _profile.zodiacSign),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(l10n, widget.dependencies.nowLocal()),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            // Scaled down rather than ellipsized: the default
                            // name (no profile name typed yet) runs long in some
                            // languages, and a mid-word ellipsis next to the
                            // header icons read as broken layout rather than a
                            // graceful truncation.
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  profileDisplayName(l10n, _profile),
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8 + HeaderSettingsCapsule.collapsedWidth),
          ],
        ),
        HeaderSettingsCapsule(
          key: _settingsCapsuleKey,
          isOpen: _isSettingsOpen,
          onToggle: () {
            setState(() => _isSettingsOpen = !_isSettingsOpen);
          },
          onClose: () {
            if (_isSettingsOpen) {
              setState(() => _isSettingsOpen = false);
            }
          },
          localeController: widget.dependencies.localeController,
          onOpenResponsibleUse: () => showResponsibleUseSheet(
            context,
            analytics: widget.dependencies.analytics,
          ),
          onOpenHistory: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HistoryPage(dependencies: widget.dependencies),
            ),
          ),
        ),
      ],
    );
  }

  /// Says plainly what the app is for, without promising certainty.
  Widget _positioning(AppLocalizations l10n) {
    final description = _description;
    return Column(
      key: const Key('home_positioning'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.homeTitle,
            maxLines: 1,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        const SizedBox(height: 8),
        // Reserve space only while the saved description is loading. Once it
        // arrives, let short and long lines take their natural height.
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: description == null ? 63 : 0),
          child: Text(
            // The index is what the deck saved; the sentence is resolved here,
            // so a language switch re-reads the same line in the new language
            // and consumes nothing.
            description == null ? '' : homeDescriptionAt(l10n, description),
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
  Widget _categorySelector(AppLocalizations l10n) {
    return Wrap(
      key: const Key('category_selector'),
      spacing: 8,
      runSpacing: 8,
      children: categoryChoices.map((choice) {
        final selected = choice.category == _category;
        final label = categoryLabel(l10n, choice.category);
        return Semantics(
          button: true,
          selected: selected,
          label: label,
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
                  // Flexible so a longer translation wraps inside the chip
                  // instead of pushing the row past a 360dp screen.
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? CompassColors.blueLight
                            : CompassColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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

  Widget _dailySignals(AppLocalizations l10n) {
    final today = widget.dependencies.nowLocal();
    final localeName = intlLocaleOf(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dailyEnergy.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CompassColors.gold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: trackingFor(context, 1.6),
                  ),
                ),
              ),
              Text(
                formatShortDate(localeName, today),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CompassColors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<engine.DailyBrief?>(
            key: const Key('daily_signals_content'),
            future: _dailyBrief,
            builder: (context, snapshot) {
              // Only a *finished* future speaks for the profile on screen.
              // `FutureBuilder` keeps the previous future's value while the
              // next one is waiting — `AsyncSnapshot.inState` changes the
              // connection state and carries the data across — so reading
              // `snapshot.data` directly showed the old profile's energy,
              // colours and lucky number under the new profile's name for as
              // long as the recalculation took.
              final brief = snapshot.connectionState == ConnectionState.done
                  ? snapshot.data
                  : null;
              final colors = brief?.colors;
              final energy = brief?.energy;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                energyLevelLabel(l10n, energy?.level) ?? '—',
                                key: const Key('daily_energy_label'),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: CompassColors.text,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: trackingFor(context, 1.2),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 4),
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
                      ),
                      DailyEnergyCapsuleBar(
                        key: const Key('daily_energy_capsule_bar'),
                        energy: energy,
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
                            label: l10n.yourColorsToday,
                            // Equal-width columns keep both colours on one
                            // baseline, even in the half-width signal tile.
                            value: Row(
                              children: [
                                Expanded(
                                  child: _Swatch(
                                    color: colors?.lead,
                                    role: l10n.colorRoleLead,
                                    testKey: 'daily_color_lead',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _Swatch(
                                    color: colors?.supporting,
                                    role: l10n.colorRoleSupporting,
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
                            label: l10n.luckyNumberToday,
                            value: Text(
                              brief == null
                                  ? '—'
                                  : formatWholeNumber(
                                      localeName,
                                      brief.luckyNumber,
                                    ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: brief == null
                                    ? CompassColors.text
                                    : CompassColors.blueLight,
                                fontSize: 30,
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

  Widget _modeGrid(AppLocalizations l10n) {
    Widget card(DecisionMode mode) => _ModeCard(
      first: modeFirstLabel(l10n, mode),
      second: modeSecondLabel(l10n, mode),
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
            Expanded(child: card(DecisionMode.commitWithdraw)),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: CompassColors.secondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          // Only the value is centred; the label stays where it was.
          Center(child: value),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.first,
    required this.second,
    required this.selected,
    required this.onTap,
  });

  /// Two already-localized tokens and a separator, never an English label to
  /// be split on punctuation.
  final String first;
  final String second;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                first,
                maxLines: 1,
                style: TextStyle(
                  color: selected
                      ? CompassColors.blueLight
                      : CompassColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '/',
                  style: TextStyle(
                    color: CompassColors.muted.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(
                second,
                maxLines: 1,
                style: TextStyle(
                  color: selected
                      ? CompassColors.blueLight
                      : CompassColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the day's two colours: just the swatch. Its name only some
/// languages' translations run long enough to crowd the narrow column next
/// to its twin, so it is not printed underneath any more — tapping the
/// swatch reveals it in a tab instead, the way the daily-energy ⓘ does.
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
    final l10n = AppLocalizations.of(context);
    final circle = Container(
      width: 20,
      height: 20,
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
    );

    return Semantics(
      label: color == null
          ? l10n.colorRoleUnavailableSemantics(role)
          : l10n.colorRoleSemantics(role, dailyColorName(l10n, color!)),
      child: Center(
        key: Key(testKey),
        child: color == null
            ? circle
            : Tooltip(
                message: dailyColorName(l10n, color!),
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 4),
                textStyle: const TextStyle(
                  color: CompassColors.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  color: CompassColors.raised,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CompassColors.line),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: circle,
              ),
      ),
    );
  }
}
