import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../mock_reading_engine.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import 'result_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({
    super.key,
    required this.mode,
    required this.period,
    required this.zodiacSign,
  });

  final DecisionMode mode;
  final TimePeriod period;
  final ZodiacSign zodiacSign;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  static const _reassurance =
      'Give me a moment — I’m still bringing your cosmic signals into focus.';

  final List<Timer> _timers = [];
  late final List<String> _phrases;
  late final int _durationMs;
  var _phraseIndex = 0;
  var _showingReassurance = false;
  var _reassuranceShown = false;
  DateTime? _lastTapAt;

  @override
  void initState() {
    super.initState();
    _durationMs = 4200 + Random().nextInt(1001);
    _phrases = [
      'Synchronizing with your local time and hour',
      'Reading your BaZi elemental balance',
      'Mapping Zi Wei cycles around this moment',
      'Tracing numerology, lunar and planetary rhythms',
      widget.mode.ritualCopy,
      'Balancing Yin and Yang signals into one direction',
    ];

    _timers.add(
      Timer.periodic(const Duration(milliseconds: 720), (timer) {
        if (!mounted || _showingReassurance) return;
        if (_phraseIndex < _phrases.length - 1) {
          setState(() => _phraseIndex++);
        }
      }),
    );
    _timers.add(Timer(Duration(milliseconds: _durationMs), _showResult));
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _registerTap() {
    if (MediaQuery.of(context).accessibleNavigation || _reassuranceShown)
      return;
    final now = DateTime.now();
    final previous = _lastTapAt;
    _lastTapAt = now;
    if (previous == null || now.difference(previous).inMilliseconds > 900)
      return;

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

  void _showResult() {
    if (!mounted) return;
    final result = createMockReading(widget.mode, widget.period);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 760),
        pageBuilder: (_, animation, secondaryAnimation) =>
            ResultPage(result: result),
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
                sign: widget.zodiacSign,
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
