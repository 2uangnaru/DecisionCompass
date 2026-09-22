import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../data/models/models.dart' as engine;
import '../data/reading_api_exception.dart';
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
    required this.profile,
    required this.instantUtc,
    required this.dependencies,
  });

  final DecisionMode mode;
  final TimePeriod period;
  final AppProfile profile;

  /// The instant the Reveal tap happened, recorded by [RitualPage].
  final DateTime instantUtc;

  final ReadingDependencies dependencies;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  static const _reassurance =
      'Give me a moment — I’m still bringing your cosmic signals into focus.';

  /// The ritual is never shorter than this, even when the API answers at once.
  static const _minimumRitual = Duration(milliseconds: 4200);
  static const _ritualJitterMs = 1001;

  final List<Timer> _timers = [];
  late final List<String> _phrases;
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
    _phrases = [
      'Synchronizing with your local time and hour',
      'Reading your BaZi elemental balance',
      'Mapping Zi Wei cycles around this moment',
      'Tracing numerology, lunar and planetary rhythms',
      widget.mode.ritualCopy,
      'Balancing Yin and Yang signals into one direction',
    ];
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
        if (_phraseIndex < _phrases.length - 1) {
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
      includeLocation: widget.profile.useCurrentLocation,
    );
    // `diagnostics` is intentionally omitted: the API rejects it, and module
    // internals must never reach the app.
    return engine.ReadingRequest(
      profile: widget.profile.toBirthProfile(),
      context: context,
      mode: toEngineMode(widget.mode),
      period: toEnginePeriod(widget.period),
      category: engine.ReadingCategory.general,
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
          if (_phraseIndex < _phrases.length - 1) _phraseIndex++;
        });
      }),
    );
  }

  void _showResult(engine.ReadingResponse reading) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 760),
        pageBuilder: (_, animation, secondaryAnimation) =>
            ResultPage(reading: reading),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                child: child,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null)
      return _ReadingErrorView(failure: failure, onRetry: _retry);

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
                widget.mode.label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: CompassColors.gold, letterSpacing: 1.8),
              ),
              const Spacer(),
              OrbitVisual(
                size: compact ? 220 : 300,
                sign: widget.profile.zodiacSign,
                labels: [
                  'BAZI',
                  'ZI WEI',
                  'CAN CHI',
                  'NUMEROLOGY',
                  'LUNAR PHASE',
                  'PLANETARY',
                  'YIN / YANG',
                  'MOMENT',
                ],
              ),
              SizedBox(height: compact ? 22 : 38),
              SizedBox(
                height: 66,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    _showingReassurance ? _reassurance : _phrases[_phraseIndex],
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
                  _phrases.length,
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
                'READING YOUR LOCAL MOMENT',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: CompassColors.muted, letterSpacing: 1.3),
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
  const _ReadingErrorView({required this.failure, required this.onRetry});

  final ReadingApiException failure;
  final VoidCallback onRetry;

  String get _headline => switch (failure.kind) {
    ReadingApiFailureKind.timeout ||
    ReadingApiFailureKind.network => 'The connection slipped out of alignment.',
    ReadingApiFailureKind.server =>
      'The reading could not be completed right now.',
    ReadingApiFailureKind.rejectedRequest =>
      'Some profile details need attention.',
    ReadingApiFailureKind.invalidResponse =>
      'This app version could not read the result.',
    ReadingApiFailureKind.configuration =>
      'This build has no reading service configured.',
  };

  String get _detail => switch (failure.kind) {
    ReadingApiFailureKind.timeout || ReadingApiFailureKind.network =>
      'Check your connection, then try the reading again.',
    ReadingApiFailureKind.server =>
      'The service is there but could not finish. Try again in a moment.',
    ReadingApiFailureKind.rejectedRequest =>
      'Revisit your birth details, then start a new reading.',
    ReadingApiFailureKind.invalidResponse =>
      'Updating the app should restore readings.',
    ReadingApiFailureKind.configuration =>
      'Developer build: pass --dart-define=DECISION_API_BASE_URL to point at '
          'the calculation API.',
  };

  /// Only the transient kinds can be retried; a rejected request or a contract
  /// mismatch would fail identically however many times it is sent.
  bool get _canRetry => switch (failure.kind) {
    ReadingApiFailureKind.timeout ||
    ReadingApiFailureKind.network ||
    ReadingApiFailureKind.server => true,
    ReadingApiFailureKind.rejectedRequest ||
    ReadingApiFailureKind.invalidResponse ||
    ReadingApiFailureKind.configuration => false,
  };

  @override
  Widget build(BuildContext context) {
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
              _headline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              _detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            if (_canRetry) ...[
              FilledButton.icon(
                key: const Key('retry_reading'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
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
              label: const Text('Back'),
            ),
            const SizedBox(height: 24),
            Text(
              'No reading was recorded for this attempt.',
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
