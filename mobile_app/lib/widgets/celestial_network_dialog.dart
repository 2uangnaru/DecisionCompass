import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// The celestial "no connection" dialog (visual design: Antigravity).
///
/// It cannot be dismissed by the barrier or Back. It closes only when
/// [isOnline] answers true: from the Reconnect button, or from its own check
/// every [pollEvery], so it also goes away when the connection returns by
/// itself.
Future<void> showCelestialNetworkDialog(
  BuildContext context, {
  required Future<bool> Function() isOnline,
  Duration pollEvery = const Duration(seconds: 4),
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: Dialog(
        key: const Key('network_dialog'),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF0182642), Color(0xF80D1527)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: CompassColors.gold.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: CompassColors.gold.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: _CelestialNetworkContent(
              isOnline: isOnline,
              pollEvery: pollEvery,
              onOnline: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CelestialNetworkContent extends StatefulWidget {
  const _CelestialNetworkContent({
    required this.isOnline,
    required this.pollEvery,
    required this.onOnline,
  });

  final Future<bool> Function() isOnline;
  final Duration pollEvery;
  final VoidCallback onOnline;

  @override
  State<_CelestialNetworkContent> createState() =>
      _CelestialNetworkContentState();
}

class _CelestialNetworkContentState extends State<_CelestialNetworkContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarController;
  Timer? _poll;
  bool _checking = false, _stillOffline = false, _closed = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _poll = Timer.periodic(widget.pollEvery, (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  /// A silent check is the dialog's own poll: it never shows the spinner or
  /// the "still offline" line, which belong to the reader's tap.
  Future<void> _check({bool silent = false}) async {
    if (_checking || _closed) return;
    _checking = true;
    if (!silent) setState(() => _stillOffline = false);
    bool online;
    try {
      online = await widget.isOnline();
    } catch (_) {
      online = false;
    }
    _checking = false;
    if (!mounted || _closed) return;
    if (online) {
      _closed = true;
      widget.onOnline();
    } else {
      setState(() => _stillOffline = _stillOffline || !silent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _checking && !_closed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing beacon. It loops, so it repaints on its own layer.
        RepaintBoundary(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) => CustomPaint(
                    size: const Size(80, 80),
                    painter: _BeaconRadarPainter(_radarController.value),
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF223758), Color(0xFF0E1729)],
                    ),
                    border: Border.all(color: CompassColors.gold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: CompassColors.gold.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.wifi_find_rounded,
                      size: 30,
                      color: CompassColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: CompassColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CompassColors.gold.withValues(alpha: 0.35),
            ),
          ),
          // The star is an icon: the bundled fonts carry no U+2726.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 11,
                color: CompassColors.gold,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  l10n.networkDialogTag,
                  style: const TextStyle(
                    color: CompassColors.gold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.networkDialogTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.networkDialogBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: CompassColors.secondary,
            fontSize: 13,
            height: 1.55,
          ),
        ),
        if (_stillOffline) ...[
          const SizedBox(height: 12),
          Text(
            l10n.networkDialogStillOffline,
            key: const Key('network_still_offline'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CompassColors.gold.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            key: const Key('network_retry'),
            onPressed: busy ? null : _check,
            style: ElevatedButton.styleFrom(
              backgroundColor: CompassColors.gold,
              foregroundColor: const Color(0xFF0C1322),
              disabledBackgroundColor: CompassColors.gold.withValues(
                alpha: 0.55,
              ),
              disabledForegroundColor: const Color(0xFF0C1322),
              elevation: 4,
              shadowColor: CompassColors.gold.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            child: busy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0C1322),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(l10n.networkDialogChecking)),
                    ],
                  )
                : Text(l10n.networkDialogRetry),
          ),
        ),
      ],
    );
  }
}

class _BeaconRadarPainter extends CustomPainter {
  _BeaconRadarPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Expanding wave
    final waveRadius = 28.0 + (maxRadius - 28.0) * progress;
    final waveAlpha = ((1.0 - progress) * 0.45).clamp(0.0, 1.0);
    final wavePaint = Paint()
      ..color = CompassColors.blueLight.withValues(alpha: waveAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(center, waveRadius, wavePaint);

    // Rotating orbital dot
    final orbitRadius = maxRadius - 2;
    final dotPaint = Paint()
      ..color = CompassColors.gold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, orbitRadius, dotPaint);

    final angle = progress * 2 * math.pi;
    final dotPos = Offset(
      center.dx + orbitRadius * math.cos(angle),
      center.dy + orbitRadius * math.sin(angle),
    );
    final starDot = Paint()
      ..color = CompassColors.gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotPos, 2.0, starDot);
  }

  @override
  bool shouldRepaint(covariant _BeaconRadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
