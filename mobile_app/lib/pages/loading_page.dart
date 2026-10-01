import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../data/models/models.dart' as engine;
import '../data/period_availability.dart';
import '../data/reading_api_exception.dart';
import '../l10n/app_localizations.dart';
import '../local_engine/time/local_time.dart' show validZone;
import '../localized_presentation.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../reading_mapping.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import 'result_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({
    super.key,
    required this.mode,
    required this.period,
    required this.category,
    required this.profile,
    required this.instantUtc,
    required this.dependencies,
  });

  final DecisionMode mode;
  final TimePeriod period;
  final engine.ReadingCategory category;
  final AppProfile profile;

  /// The instant the Reveal tap happened, recorded by [RitualPage].
  final DateTime instantUtc;

  final ReadingDependencies dependencies;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  /// How many narration lines the ritual steps through. The text itself is
  /// resolved at build time from the active language, so only the position in
  /// the sequence is state.
  static const _phraseCount = 7;

  /// The ritual is never shorter than this, even when the API answers at once.
  static const _minimumRitual = Duration(milliseconds: 5040);
  static const _ritualJitterMs = 250;

  final List<Timer> _timers = [];
  late final int _durationMs;
  var _phraseIndex = 0;
  var _showingReassurance = false;
  var _reassuranceShown = false;
  DateTime? _lastTapAt;

  /// Built once and reused, so a retry replays the original Reveal moment
  /// instead of quietly moving it.
  engine.ReadingRequest? _request;
  ReadingApiException? _failure;
  var _attemptRunning = false;

  @override
  void initState() {
    super.initState();
    _durationMs =
        _minimumRitual.inMilliseconds + Random().nextInt(_ritualJitterMs);
    _startPhraseCycle();
    _runAttempt();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _startPhraseCycle() {
    _cancelTimers();
    _timers.add(
      Timer.periodic(const Duration(milliseconds: 720), (timer) {
        if (!mounted || _showingReassurance) return;
        if (_phraseIndex < _phraseCount - 1) {
          setState(() => _phraseIndex++);
        }
      }),
    );
  }

  /// Runs the reading once. The API call and the ritual floor run
  /// concurrently: whichever finishes first waits for the other.
  Future<void> _runAttempt() async {
    if (_attemptRunning) return; // Guards rebuilds and repeated retry taps.
    _attemptRunning = true;

    final ritualFloor = Future<void>.delayed(
      Duration(milliseconds: _durationMs),
    );
    try {
      final request = _request ??= await _buildRequest();
      final reading = await widget.dependencies.repository.calculate(request);
      await ritualFloor;
      if (!mounted) return;
      _attemptRunning = false;
      _showResult(reading);
    } on ReadingApiException catch (failure) {
      await ritualFloor;
      _settleFailure(failure);
    } catch (_) {
      // Anything else is a client-side bug. Surfacing the generic contract
      // message beats leaving the ritual spinning forever, and still leaks
      // nothing.
      await ritualFloor;
      _settleFailure(
        const ReadingApiException(
          kind: ReadingApiFailureKind.invalidResponse,
          safeCode: 'unexpected_reading_failure',
          // Developer-facing only: the reader sees `_ReadingErrorView`'s own
          // localized copy, never this string.
          safeMessage: 'The reading could not be read by this app version.',
        ),
      );
    }
  }

  void _settleFailure(ReadingApiException failure) {
    if (!mounted) return;
    _cancelTimers();
    setState(() {
      _attemptRunning = false;
      _failure = failure;
    });
  }

  Future<engine.ReadingRequest> _buildRequest() async {
    // The profile carries the user's explicit choice; a retry reuses the
    // request built here, so location is never queried a second time.
    final context = await widget.dependencies.contextProvider.capture(
      instantUtc: widget.instantUtc,
      // GPS cannot improve the current result until coordinate-to-zone
      // geometry ships. Ignore even a previously saved opt-in in this build.
      includeLocation: false,
    );
    // The last gate before a live reading exists, and the only one that can
    // use the zone the reading itself is about to be calculated in. The
    // ritual screen checks the same thing at the tap, but it checks a chip;
    // this checks the request. Any future way into a live reading — a
    // notification, a deep link, a "read this again" — arrives here too.
    _refuseClosedPeriod(context.deviceTimezone);
    // `diagnostics` is intentionally omitted: the API rejects it, and module
    // internals must never reach the app.
    return engine.ReadingRequest(
      profile: widget.profile.toBirthProfile(),
      context: context,
      mode: toEngineMode(widget.mode),
      period: toEnginePeriod(widget.period),
      category: widget.category,
    );
  }

  /// Throws rather than calculating when the chosen period has closed.
  ///
  /// [zone] is the timezone carried by the captured context, which is the one
  /// the engine will resolve the reading in — not whatever this screen or the
  /// host machine believes.
  void _refuseClosedPeriod(String zone) {
    if (widget.period == TimePeriod.now) return;
    if (!validZone(zone)) return; // The engine rejects it, with its own error.
    final availability = periodAvailability(
      widget.period,
      instantUtc: widget.instantUtc,
      timezone: zone,
    );
    if (availability.selectable) return;
    throw ReadingApiException(
      kind: ReadingApiFailureKind.periodClosed,
      safeCode: 'period_closed_${availability.status.name}',
      // Developer-facing only; the reader sees `_ReadingErrorView`'s localized
      // copy. It names no zone, no instant and nothing about the reader.
      safeMessage: 'The selected period had closed when Reveal was tapped.',
    );
  }

  void _retry() {
    if (_attemptRunning) return;
    setState(() {
      _failure = null;
      _phraseIndex = 0;
      _showingReassurance = false;
    });
    _startPhraseCycle();
    _runAttempt();
  }

  void _registerTap() {
    if (MediaQuery.of(context).accessibleNavigation || _reassuranceShown) {
      return;
    }
    final now = DateTime.now();
    final previous = _lastTapAt;
    _lastTapAt = now;
    if (previous == null || now.difference(previous).inMilliseconds > 900) {
      return;
    }

    _reassuranceShown = true;
    setState(() => _showingReassurance = true);
    _timers.add(
      Timer(const Duration(milliseconds: 780), () {
        if (!mounted) return;
        setState(() {
          _showingReassurance = false;
          if (_phraseIndex < _phraseCount - 1) _phraseIndex++;
        });
      }),
    );
  }

  void _showResult(engine.ReadingResponse reading) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, secondaryAnimation) =>
            ResultPage(reading: reading, dependencies: widget.dependencies),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null)
      return _ReadingErrorView(
        failure: failure,
        period: widget.period,
        onRetry: _retry,
      );

    final l10n = AppLocalizations.of(context);
    final phrases = loadingPhrases(l10n, widget.mode);
    assert(phrases.length == _phraseCount);
    final category = categoryLabel(l10n, widget.category);
    final compact = MediaQuery.sizeOf(context).height < 700;
    return CelestialScaffold(
      child: Listener(
        key: const Key('loading_tap_surface'),
        behavior: HitTestBehavior.opaque,
        onPointerUp: (_) => _registerTap(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
          child: Column(
            children: [
              Text(
                modeLabel(l10n, widget.mode),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: CompassColors.gold,
                  letterSpacing: trackingFor(context, 1.8),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: l10n.readingAreaSemantics(category),
                child: Text(
                  key: const Key('loading_category_label'),
                  l10n.readingForCategory(category),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CompassColors.blueLight,
                    letterSpacing: trackingFor(context, 1),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                key: const Key('loading_period_label'),
                periodLabel(l10n, widget.period),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CompassColors.muted,
                  letterSpacing: trackingFor(context, 1.1),
                ),
              ),
              const Spacer(),
              OrbitVisual(
                size: compact ? 220 : 300,
                sign: widget.profile.zodiacSign,
                labels: loadingOrbitLabels(l10n),
              ),
              SizedBox(height: compact ? 22 : 38),
              SizedBox(
                height: 66,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    _showingReassurance
                        ? l10n.loadingReassurance
                        : phrases[_phraseIndex],
                    key: ValueKey('${_showingReassurance}_$_phraseIndex'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _showingReassurance
                          ? CompassColors.blueLight
                          : CompassColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _phraseCount,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _phraseIndex ? 20 : 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index <= _phraseIndex
                          ? CompassColors.blueLight
                          : CompassColors.line,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                l10n.loadingLocalMoment,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CompassColors.muted,
                  letterSpacing: trackingFor(context, 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-theme failure state. Shows only app-owned copy: never the exception's
/// own text, a server body, birth data or coordinates.
class _ReadingErrorView extends StatelessWidget {
  const _ReadingErrorView({
    required this.failure,
    required this.period,
    required this.onRetry,
  });

  final ReadingApiException failure;

  /// Only used by [ReadingApiFailureKind.periodClosed], which names the
  /// period it refused rather than saying something went wrong.
  final TimePeriod period;
  final VoidCallback onRetry;

  String _headline(AppLocalizations l10n) => switch (failure.kind) {
    ReadingApiFailureKind.timeout ||
    ReadingApiFailureKind.network => l10n.errorNetworkHeadline,
    ReadingApiFailureKind.server => l10n.errorServerHeadline,
    ReadingApiFailureKind.rejectedRequest => l10n.errorRejectedHeadline,
    ReadingApiFailureKind.invalidResponse => l10n.errorInvalidHeadline,
    ReadingApiFailureKind.configuration => l10n.errorConfigurationHeadline,
    // Not a failure to say sorry for: the day simply moved on.
    ReadingApiFailureKind.periodClosed => l10n.periodTooLittleTime,
  };

  String _detail(AppLocalizations l10n) => switch (failure.kind) {
    ReadingApiFailureKind.timeout ||
    ReadingApiFailureKind.network => l10n.errorNetworkDetail,
    ReadingApiFailureKind.server => l10n.errorServerDetail,
    ReadingApiFailureKind.rejectedRequest => l10n.errorRejectedDetail,
    ReadingApiFailureKind.invalidResponse => l10n.errorInvalidDetail,
    ReadingApiFailureKind.configuration => l10n.errorConfigurationDetail,
    ReadingApiFailureKind.periodClosed => failure.safeCode.endsWith('passed')
        ? l10n.periodHasPassed(periodLabel(l10n, period))
        : l10n.periodNotEnoughTimeLeft(periodLabel(l10n, period)),
  };

  /// Only the transient kinds can be retried; a rejected request or a contract
  /// mismatch would fail identically however many times it is sent.
  bool get _canRetry => switch (failure.kind) {
    ReadingApiFailureKind.timeout ||
    ReadingApiFailureKind.network ||
    ReadingApiFailureKind.server => true,
    ReadingApiFailureKind.rejectedRequest ||
    ReadingApiFailureKind.invalidResponse ||
    ReadingApiFailureKind.configuration ||
    // Retrying would only re-check the same instant against the same clock.
    ReadingApiFailureKind.periodClosed => false,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CelestialScaffold(
      child: SingleChildScrollView(
        key: const Key('reading_error'),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Center(
              child: Icon(
                Icons.blur_circular_rounded,
                size: 64,
                color: CompassColors.gold,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              _headline(l10n),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              _detail(l10n),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            if (_canRetry) ...[
              FilledButton.icon(
                key: const Key('retry_reading'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.tryAgain),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              key: const Key('back_from_error'),
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.backAction),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.errorNothingRecorded,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: CompassColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
