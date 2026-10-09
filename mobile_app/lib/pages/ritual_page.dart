import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../data/models/models.dart' as engine;
import '../data/period_availability.dart';
import '../local_engine/time/local_time.dart' show validZone;
import '../l10n/app_localizations.dart';
import '../localized_presentation.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../widgets/ad_banner_slot.dart';
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
    this.isCooldown,
    this.isQuotaExhausted,
  });

  final DecisionMode mode;
  final TimePeriod period;
  final engine.ReadingCategory category;
  final AppProfile profile;
  final ReadingDependencies dependencies;
  final ValueChanged<AppProfile>? onSafetyAcknowledged;

  /// Optional override for testing/previewing cooldown state.
  final bool? isCooldown;

  /// Optional override for testing/previewing daily quota exhausted state.
  final bool? isQuotaExhausted;

  @override
  State<RitualPage> createState() => _RitualPageState();
}

class _RitualPageState extends State<RitualPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  var _locked = false;
  var _checkingEntitlement = false;
  late bool _isCooldown;
  bool? _isQuotaExhaustedOverride;
  late String _countdownString;
  Timer? _countdownTimer;
  Timer? _periodRefreshTimer;
  late final AnimationController _pulseController;
  late AppProfile _profile = widget.profile;

  bool get _isQuotaExhausted {
    if (_isQuotaExhaustedOverride != null) {
      return _isQuotaExhaustedOverride!;
    }
    if (widget.isQuotaExhausted != null) {
      return widget.isQuotaExhausted!;
    }
    final now = widget.dependencies.nowLocal();
    final quota = widget.dependencies.quotaManager;
    return quota.bonusReadings == 0 &&
        quota.dailyFreeReadingsUsed(now) >= quota.maxDailyFreeReadings;
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    if (!_isCooldown && !_isQuotaExhausted) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = widget.dependencies.nowLocal();
      final remaining = widget.dependencies.quotaManager.remainingCooldown(now);
      if (remaining <= Duration.zero &&
          widget.dependencies.quotaManager.isAvailable(now)) {
        timer.cancel();
        setState(() {
          _isCooldown = false;
          _isQuotaExhaustedOverride = false;
          _countdownString = '00:00:00';
        });
      } else {
        setState(() {
          _countdownString = widget.dependencies.quotaManager
              .remainingTimeString(now);
        });
      }
    });
  }

  /// The floating locked/status notice currently on screen, or null for none.
  String? _notice;
  Timer? _noticeTimer;
  bool _noticeHolding = false;
  static const Duration _noticeDuration = Duration(milliseconds: 3000);

  late final AnimationController _noticeAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _noticeFade = CurvedAnimation(
    parent: _noticeAnimation,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<Offset> _noticeSlide =
      Tween<Offset>(begin: const Offset(-0.18, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _noticeAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: const Threshold(0),
        ),
      );

  void _showNotice(String message) {
    if (_noticeHolding && _notice == message) return;
    _noticeTimer?.cancel();
    setState(() {
      _notice = message;
      _noticeHolding = true;
    });
    if (MediaQuery.of(context).disableAnimations) {
      _noticeAnimation.value = 1;
    } else {
      _noticeAnimation.forward(from: 0);
    }
    _noticeTimer = Timer(_noticeDuration, _hideNotice);
  }

  void _hideNotice() {
    if (!mounted || _notice == null) return;
    _noticeHolding = false;
    if (MediaQuery.of(context).disableAnimations) {
      _noticeAnimation.value = 0;
      setState(() => _notice = null);
      return;
    }
    _noticeAnimation.reverse().then((_) {
      if (mounted && _noticeAnimation.value == 0) {
        setState(() => _notice = null);
      }
    });
  }

  Future<void> _watchAdAndUnlock() async {
    await widget.dependencies.quotaManager.earnBonusReading();
    if (!mounted) return;
    setState(() {
      _isCooldown = false;
      _isQuotaExhaustedOverride = false;
    });
    _countdownTimer?.cancel();
    final l10n = AppLocalizations.of(context);
    _showNotice(l10n.adUnlockedReward);
  }

  void _notifyCooldownLocked() {
    final l10n = AppLocalizations.of(context);
    final message = _isQuotaExhausted
        ? l10n.quotaExhaustedNotice
        : l10n.energyAccumulating;
    _showNotice(message);
  }

  /// The IANA zone a reading taken now would resolve to.
  ///
  /// The reader's IANA zone, once it is known.
  ///
  /// Until it is, no named period can be chosen. How much of Morning is left
  /// is a question about the reader's clock, and an app that has not read that
  /// clock does not know the answer — offering the period anyway would be
  /// claiming it has time left on the strength of never having looked.
  String? _timezone;

  /// Whether the lookup is in flight, done, or failed. Drives the chip suffix
  /// and the retry control.
  _ZoneLookup _zoneLookup = _ZoneLookup.resolving;

  /// Guards against a Reveal tap starting a second lookup on top of the one
  /// the screen started when it opened.
  bool _resolvingZone = false;

  /// When the reading is for. Chosen here, beside the Reveal tap, so the
  /// moment and the period are picked together.
  late TimePeriod _period = widget.period;

  @override
  void initState() {
    super.initState();
    _isQuotaExhaustedOverride = widget.isQuotaExhausted;
    final now = widget.dependencies.nowLocal();
    final quota = widget.dependencies.quotaManager;
    final isExhausted =
        widget.isQuotaExhausted ??
        (quota.bonusReadings == 0 &&
            quota.dailyFreeReadingsUsed(now) >= quota.maxDailyFreeReadings);

    _isCooldown = widget.isCooldown ?? (isExhausted || quota.isCooldown(now));

    _countdownString = quota.remainingTimeString(now);
    if (_isCooldown || isExhausted) {
      _startCountdownTimer();
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addObserver(this);
    _resolveTimezone();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    _noticeTimer?.cancel();
    _noticeAnimation.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Reads the reader's zone, and re-reads it on demand.
  ///
  /// Returns the zone, or null when it could not be established — either
  /// because the platform refused, or because it named a zone this build's tz
  /// database has never heard of, which is the same thing as far as working
  /// out how much of a local period is left.
  Future<String?> _resolveTimezone() async {
    if (_resolvingZone) return _timezone;
    _resolvingZone = true;
    if (mounted && _timezone == null) {
      setState(() => _zoneLookup = _ZoneLookup.resolving);
    }
    String? zone;
    try {
      zone = await widget.dependencies.contextProvider.currentTimezone();
      if (!validZone(zone)) zone = null;
    } catch (_) {
      zone = null;
    } finally {
      _resolvingZone = false;
    }
    if (!mounted) return zone;
    if (zone == null) {
      // Not "every period is fine": every named period is unanswerable, and
      // the chips say so, with a way to ask again. Any zone read earlier is
      // discarded rather than kept as a best guess — a lookup that fails at
      // the Reveal tap may be failing because the device's zone just changed.
      setState(() {
        _timezone = null;
        _zoneLookup = _ZoneLookup.failed;
      });
      _periodRefreshTimer?.cancel();
      _dropSelectionIfClosed();
      return null;
    }
    setState(() {
      _timezone = zone;
      _zoneLookup = _ZoneLookup.resolved;
    });
    // Every chip is now answerable, and a selection made before the zone
    // arrived may already be closed on the reader's own clock.
    _dropSelectionIfClosed();
    _schedulePeriodRefresh();
    return zone;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background can land well past a cutoff the timer
    // never got to fire for. The repaint is unconditional: a period the reader
    // did *not* pick can close while they are away, and only redrawing when
    // their own choice expired would leave the other chips lying.
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    setState(() {});
    _dropSelectionIfClosed();
    _schedulePeriodRefresh();
  }

  /// The availability of [period] at this instant, by the reader's own zone.
  ///
  /// [zone] overrides the resolved one, so the Reveal tap can judge the
  /// selection by the zone the reading itself is about to use rather than by
  /// the one this screen happened to read when it opened.
  PeriodAvailability _availability(
    TimePeriod period, {
    DateTime? at,
    String? zone,
  }) {
    // NOW is the instant of the tap. It has no end and needs no clock, so it
    // survives a zone that never resolves.
    if (period.localHours == null) return PeriodAvailability.now;
    final resolved = zone ?? _timezone;
    if (resolved == null) return PeriodAvailability.unknownTimezone;
    return periodAvailability(
      period,
      instantUtc: at ?? widget.dependencies.nowUtc(),
      timezone: resolved,
    );
  }

  /// If the chosen period has closed, fall back to NOW and say why.
  ///
  /// Quietly leaving a closed period selected would let the reader tap Reveal
  /// on something that cannot produce a reading; quietly swapping in a
  /// different named period would answer a question they did not ask.
  void _dropSelectionIfClosed({DateTime? at, String? zone}) {
    if (!mounted || _locked) return;
    final availability = _availability(_period, at: at, zone: zone);
    if (availability.selectable) return;
    final closed = _period;
    setState(() => _period = TimePeriod.now);
    final l10n = AppLocalizations.of(context);
    final label = periodLabel(l10n, closed);
    final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('ritual_period_closed_notice'),
        duration: const Duration(seconds: 4),
        content: Text(switch (availability.status) {
          PeriodStatus.passed => l10n.periodHasPassed(label),
          PeriodStatus.unknownTimezone => l10n.timezoneUnavailableNotice,
          _ => l10n.periodNotEnoughTimeLeft(label),
        }),
      ),
    );
  }

  /// Re-render exactly when a period's availability actually changes — when
  /// it drops under its cutoff, when it ends, and when the local date turns
  /// over and re-opens them all — rather than on a poll.
  void _schedulePeriodRefresh() {
    _periodRefreshTimer?.cancel();
    final zone = _timezone;
    if (zone == null) return;
    final now = widget.dependencies.nowUtc();
    final next = nextAvailabilityChange(instantUtc: now, timezone: zone);
    if (next == null) return;
    final wait = next.difference(now.toUtc());
    _periodRefreshTimer = Timer(
      wait > Duration.zero ? wait : const Duration(seconds: 1),
      () {
        if (!mounted) return;
        setState(() {});
        _dropSelectionIfClosed();
        _schedulePeriodRefresh();
      },
    );
  }

  /// Re-checks the selection against the instant of this very tap.
  ///
  /// The chips may have been painted minutes ago. Revalidating here, against
  /// `nowUtc()` rather than the last render, is what stops a stale selection
  /// producing a reading — and it runs before anything is captured, saved or
  /// unlocked.
  bool _rejectClosedPeriod({DateTime? at, String? zone}) {
    final instant = at ?? widget.dependencies.nowUtc();
    if (_availability(_period, at: instant, zone: zone).selectable) {
      return false;
    }
    _dropSelectionIfClosed(at: instant, zone: zone);
    return true;
  }

  Future<void> _reveal() async {
    if (_locked || _checkingEntitlement) return;
    _checkingEntitlement = true;
    try {
      final quota = widget.dependencies.quotaManager;
      await quota.ensureLoaded();
      if (!mounted) return;
      final local = widget.dependencies.nowLocal();
      if (!quota.isAvailable(local)) {
        setState(() {
          _isCooldown = true;
          _isQuotaExhaustedOverride =
              quota.bonusReadings == 0 &&
              quota.dailyFreeReadingsUsed(local) >= quota.maxDailyFreeReadings;
          _countdownString = quota.remainingTimeString(local);
        });
        _startCountdownTimer();
        _notifyCooldownLocked();
        return;
      }
      await _revealAvailable();
    } finally {
      _checkingEntitlement = false;
    }
  }

  Future<void> _revealAvailable() async {
    if (_locked) return;
    if (_isCooldown || _isQuotaExhausted) {
      _notifyCooldownLocked();
      return;
    }
    // The reading's moment is this tap, taken before any lookup, so a slow
    // one cannot move it — and it is also the instant every check below
    // judges the selection against.
    final instantUtc = widget.dependencies.nowUtc();
    // Cheap rejection first, against what the screen already knows.
    if (_rejectClosedPeriod(at: instantUtc)) return;
    // Then against the zone the reading is actually about to use. The screen
    // may have read its zone minutes ago, and a reader who has crossed a
    // border or whose device changed zone since then would otherwise have
    // their period judged by a clock that is no longer theirs.
    if (_period.localHours != null) {
      final zone = await _resolveTimezone();
      if (!mounted || _locked) return;
      // Unresolvable: `_resolveTimezone` has already dropped the selection
      // and shown why, so the period simply does not travel.
      if (zone == null) return;
      if (_rejectClosedPeriod(at: instantUtc, zone: zone)) return;
    }
    if (!_profile.safetyAcknowledged) {
      final agreed = await showResponsibleUseSheet(
        context,
        isFirstTimeAcknowledgement: true,
      );
      if (!agreed || !mounted) return;
      setState(() => _profile = _profile.copyWith(safetyAcknowledged: true));
      widget.onSafetyAcknowledged?.call(_profile);
    }
    // Checked again: the responsible-use sheet can sit open across a cutoff,
    // and this time against the tap's own instant, not the sheet's.
    if (_rejectClosedPeriod(at: instantUtc)) return;
    // A safety sheet or timezone lookup may have remained open while another
    // entry point consumed the last entitlement. UI state is not authority.
    if (!widget.dependencies.quotaManager.isAvailable(
      widget.dependencies.nowLocal(),
    )) {
      _notifyCooldownLocked();
      return;
    }
    setState(() => _locked = true);
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

  Widget _noticeOverlay(bool compact) {
    final message = _notice;
    if (message == null) return const SizedBox.shrink();
    final isSuccess = message.startsWith('✨');
    final isExhausted = _isQuotaExhausted && !isSuccess;
    final accentColor = isSuccess
        ? CompassColors.gold
        : isExhausted
        ? const Color(0xFFE27C7C)
        : CompassColors.gold;

    return Positioned(
      left: 0,
      right: 0,
      top: compact ? 44 : 50,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _noticeFade,
          child: SlideTransition(
            position: _noticeSlide,
            child: Semantics(
              container: true,
              liveRegion: true,
              label: message,
              excludeSemantics: true,
              child: Container(
                key: const Key('ritual_locked_notice'),
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CompassColors.raised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isExhausted
                        ? const Color(0xFFE27C7C).withValues(alpha: 0.45)
                        : CompassColors.line,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        isSuccess
                            ? Icons.auto_awesome
                            : Icons.hourglass_bottom_rounded,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: CompassColors.text, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return CelestialScaffold(
      // Keep the choice, reveal control and instruction in one top-to-bottom
      // flow. Spacing is kept compact and balanced so elements are never too far apart.
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 700;
                // Sized from the space actually available rather than from a
                // breakpoint, and capped by width so it never crowds the edges.
                final ringSize = math.min(
                  (constraints.maxHeight * 0.28).clamp(150.0, 220.0),
                  constraints.maxWidth * 0.62,
                );
                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        compact ? 8 : 14,
                        20,
                        compact ? 12 : 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight - (compact ? 24 : 40),
                        ),
                        child: IntrinsicHeight(
                          child: _body(
                            compact,
                            ringSize,
                            ringSize * 0.81,
                            reduceMotion,
                          ),
                        ),
                      ),
                    ),
                    _noticeOverlay(compact),
                  ],
                );
              },
            ),
          ),
          const AdBannerSlot(),
        ],
      ),
    );
  }

  Widget _body(
    bool compact,
    double ringSize,
    double buttonSize,
    bool reduceMotion,
  ) {
    final l10n = AppLocalizations.of(context);
    final selectedPeriodElapsed = !_availability(_period).selectable;
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
                modeLabel(l10n, widget.mode),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: CompassColors.gold,
                  letterSpacing: trackingFor(context, 1.8),
                ),
              ),
            ),
            IconButton(
              key: const Key('ritual_responsible_use_button'),
              tooltip: l10n.responsibleUse,
              onPressed: _locked
                  ? null
                  : () => showResponsibleUseSheet(
                      context,
                      analytics: widget.dependencies.analytics,
                    ),
              icon: const Icon(Icons.shield_outlined, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _CategoryBadge(
          key: const Key('ritual_category_badge'),
          label: categoryLabel(l10n, widget.category),
          semanticsLabel: l10n.readingAreaSemantics(
            categoryLabel(l10n, widget.category),
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        _periodSelector(l10n),
        SizedBox(height: compact ? 14 : 20),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              enabled:
                  !_locked &&
                  !selectedPeriodElapsed &&
                  !_isCooldown &&
                  !_isQuotaExhausted,
              label:
                  '${l10n.reveal}, ${periodLabel(l10n, _period)}, '
                  '${modeLabel(l10n, widget.mode)}',
              child: GestureDetector(
                key: const Key('reveal_button'),
                onTap: _locked || selectedPeriodElapsed
                    ? null
                    : ((_isCooldown || _isQuotaExhausted)
                          ? _notifyCooldownLocked
                          : _reveal),
                child: Opacity(
                  opacity: selectedPeriodElapsed ? 0.45 : 1,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulse = reduceMotion || selectedPeriodElapsed
                          ? 0.0
                          : _pulseController.value;
                      final ringScale = _locked ? 0.96 : 1 + pulse * 0.08;
                      final coreScale = _locked ? 0.96 : 1 + pulse * 0.02;

                      final auraColor = _isQuotaExhausted
                          ? const Color(0xFFE27C7C)
                                .withValues(alpha: 0.16 + pulse * 0.20)
                          : _isCooldown
                          ? const Color(0xFFE2A84B)
                                .withValues(alpha: 0.16 + pulse * 0.20)
                          : CompassColors.blueLight.withValues(
                              alpha: 0.2 + pulse * 0.28,
                            );

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
                                border: Border.all(color: auraColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: auraColor,
                                    blurRadius: 22 + pulse * 24,
                                    spreadRadius: pulse * 4,
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
                                gradient: _isQuotaExhausted
                                    ? const RadialGradient(
                                        colors: [
                                          Color(0xFF2B141C),
                                          Color(0xFF150E16),
                                        ],
                                      )
                                    : _isCooldown
                                    ? const RadialGradient(
                                        colors: [
                                          Color(0xFF231F2A),
                                          Color(0xFF131520),
                                        ],
                                      )
                                    : const RadialGradient(
                                        colors: [
                                          Color(0xFF286DA5),
                                          Color(0xFF153553),
                                        ],
                                      ),
                                border: Border.all(
                                  color: _isQuotaExhausted
                                      ? const Color(0xFFE27C7C)
                                            .withValues(alpha: 0.85)
                                      : _isCooldown
                                      ? const Color(0xFFE2A84B)
                                            .withValues(alpha: 0.85)
                                      : CompassColors.blueLight,
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isQuotaExhausted
                                        ? const Color(0xFFE27C7C)
                                              .withValues(alpha: 0.25)
                                        : _isCooldown
                                        ? const Color(0xFFE2A84B)
                                              .withValues(alpha: 0.25)
                                        : CompassColors.blueLight.withValues(
                                            alpha: 0.3,
                                          ),
                                    blurRadius: _locked ? 44 : 26 + pulse * 10,
                                    spreadRadius: _locked ? 6 : 1 + pulse * 2,
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
                                        ? l10n.aligning
                                        : selectedPeriodElapsed
                                        ? l10n.periodPassedShort
                                        : l10n.reveal,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: trackingFor(context, 2),
                                      fontWeight: FontWeight.w700,
                                      color: _isQuotaExhausted
                                          ? const Color(0xFFF5BDBD)
                                          : _isCooldown
                                          ? const Color(0xFFF3E0A2)
                                          : Colors.white,
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
            SizedBox(height: compact ? 14 : 18),
            Text(
              _locked
                  ? l10n.ritualLocked
                  : selectedPeriodElapsed
                  ? l10n.periodHasPassed(periodLabel(l10n, _period))
                  : _isQuotaExhausted
                  ? l10n.dailyQuotaExhaustedTitle(_countdownString)
                  : _isCooldown
                  ? l10n.energyCooldownTitle(_countdownString)
                  : l10n.tapWhenReady,
              key: const Key('ritual_ready_title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: (_isCooldown || _isQuotaExhausted) ? 15.5 : null,
                color: _isQuotaExhausted
                    ? const Color(0xFFE27C7C)
                    : _isCooldown
                    ? const Color(0xFFF3E0A2)
                    : null,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              (_isCooldown || _isQuotaExhausted)
                  ? l10n.watchAdPrompt
                  : l10n.keepChoiceInMind,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 12.5),
            ),
            if (_isCooldown || _isQuotaExhausted) ...[
              SizedBox(height: compact ? 10 : 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('ritual_watch_ad_button'),
                  onTap: _watchAdAndUnlock,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7.5,
                    ),
                    decoration: BoxDecoration(
                      gradient: _isQuotaExhausted
                          ? const LinearGradient(
                              colors: [Color(0xFFB95F62), Color(0xFFE27C7C)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF2477C9), Color(0xFF4EB3E8)],
                            ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isQuotaExhausted
                                      ? const Color(0xFFB95F62)
                                      : const Color(0xFF2477C9))
                                  .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎬', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.watchAdButton,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: compact ? 10 : 14),
            Text(
              l10n.ritualSafety,
              key: const Key('ritual_responsible_use_note'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CompassColors.secondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Compact chips, wrapped and centred so all five fit a 360dp phone without
  /// overflow and without competing with the reveal circle for attention.
  Widget _periodSelector(AppLocalizations l10n) {
    // Availability is read on every build, so a period that closes while the
    // screen is open stops being offered. The engine's own `period_elapsed`
    // answer stays the authority if the clock crosses a boundary after the tap.
    return Column(
      children: [
        Text(
          l10n.periodQuestion,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CompassColors.secondary,
            letterSpacing: trackingFor(context, 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('ritual_period_selector'),
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 2,
          children: TimePeriod.values.map((period) {
            final availability = _availability(period);
            final elapsed = !availability.selectable;
            final selected = period == _period;
            final label = periodLabel(l10n, period);
            // Two complete labels joined by a separator, so no language has to
            // fit "Passed" into an English sentence frame. A period that is
            // still running but under its cutoff says so instead: it has not
            // passed, there is simply not enough of it left.
            final suffix = switch (availability.status) {
              PeriodStatus.available => null,
              PeriodStatus.tooLittleTime => l10n.periodTooLittleTime,
              PeriodStatus.passed => l10n.periodPassed,
              // Not a claim about the period — a claim about this screen. It
              // has no clock to measure the period against yet.
              PeriodStatus.unknownTimezone =>
                _zoneLookup == _ZoneLookup.resolving
                    ? l10n.periodCheckingTimezone
                    : l10n.periodTimezoneUnknown,
            };
            return ChoiceChip(
              key: Key('ritual_period_${period.name}'),
              label: Text(suffix == null ? label : '$label · $suffix'),
              selected: selected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              // A null callback is what disables a chip. Elapsed periods stay
              // on screen, muted, so the whole day is still legible.
              onSelected: elapsed || _locked
                  ? null
                  : (_) {
                      // A cutoff may have passed since the last paint.
                      if (!_availability(period).selectable) {
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
        if (_zoneLookup == _ZoneLookup.failed) _zoneRetry(l10n),
      ],
    );
  }

  /// Says why the named periods are unavailable, and offers to look again.
  ///
  /// Without this the chips would simply be dead, which reads as a bug. The
  /// reading itself is not blocked: NOW is still there, and still correct,
  /// because it needs no clock but the tap's own.
  Widget _zoneRetry(AppLocalizations l10n) {
    return Padding(
      key: const Key('ritual_timezone_retry'),
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Text(
            l10n.timezoneUnavailableNotice,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: CompassColors.muted),
          ),
          TextButton(
            key: const Key('ritual_timezone_retry_button'),
            onPressed: _locked ? null : _resolveTimezone,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}

/// How far the screen has got in reading the reader's own time zone.
enum _ZoneLookup { resolving, resolved, failed }

/// Compact, calm badge naming the area the reading concerns.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    super.key,
    required this.label,
    required this.semanticsLabel,
  });

  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CompassColors.line),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CompassColors.blueLight,
            letterSpacing: trackingFor(context, 0.9),
          ),
        ),
      ),
    );
  }
}
