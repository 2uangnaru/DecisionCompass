import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import 'loading_page.dart';

class RitualPage extends StatefulWidget {
  const RitualPage({
    super.key,
    required this.mode,
    required this.period,
    required this.zodiacSign,
  });

  final DecisionMode mode;
  final TimePeriod period;
  final ZodiacSign zodiacSign;

  @override
  State<RitualPage> createState() => _RitualPageState();
}

class _RitualPageState extends State<RitualPage>
    with SingleTickerProviderStateMixin {
  var _locked = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _reveal() async {
    if (_locked) return;
    setState(() => _locked = true);
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoadingPage(
          mode: widget.mode,
          period: widget.period,
          zodiacSign: widget.zodiacSign,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    final ringSize = compact ? 188.0 : 220.0;
    final buttonSize = compact ? 150.0 : 178.0;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return CelestialScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
        child: Column(
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
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: CompassColors.gold,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const Spacer(),
            Semantics(
              button: true,
              enabled: !_locked,
              label:
                  'Find my direction for ${widget.mode.label}, ${widget.period.label}',
              child: GestureDetector(
                key: const Key('reveal_button'),
                onTap: _reveal,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulse = reduceMotion ? 0.0 : _pulseController.value;
                    return Transform.scale(
                      scale: _locked ? 0.96 : 1 + pulse * 0.022,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: ringSize,
                            height: ringSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CompassColors.blueLight.withValues(
                                  alpha: 0.2 + pulse * 0.22,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CompassColors.blueLight.withValues(
                                    alpha: 0.08 + pulse * 0.1,
                                  ),
                                  blurRadius: 24 + pulse * 18,
                                  spreadRadius: pulse * 4,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFF286DA5), Color(0xFF153553)],
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
                                  sign: widget.zodiacSign,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _locked ? 'ALIGNING' : 'REVEAL',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: compact ? 24 : 40),
            Text(
              _locked ? 'Your moment is locked.' : 'Tap when you’re ready',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Keep the choice clearly in your mind.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              '${widget.period.label.toUpperCase()}  •  LOCAL TIMING',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: CompassColors.muted, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
