import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../daily_energy_messages.dart';
import '../data/daily_energy_insight_deck.dart';
import '../theme.dart';

/// The insight a tone shipped with, before the rotation existed.
///
/// Kept as the plain "does this level say anything at all" answer for callers
/// that only need to know whether an ⓘ is worth offering. Which of the eight
/// a reader actually sees is [DailyEnergyInsightController]'s decision.
String? dailyEnergyMessage(String? level) =>
    level == null ? null : dailyEnergyMessagePools[level]?.first;

/// The grey ⓘ beside the energy label, the small tab it opens next to itself,
/// and the quiet marks that say today's insight has not been read yet.
///
/// The tab floats over the page instead of growing the card, so the signals
/// underneath do not jump while it is open. It carries the one sentence and
/// nothing else: no title, no list of the other tones, no disclaimer. Tap the
/// icon again, tap anywhere else, or scroll to dismiss it.
///
/// It renders nothing at all on a day with no energy to explain.
class DailyEnergyInfoButton extends StatefulWidget {
  const DailyEnergyInfoButton({
    super.key,
    required this.level,
    required this.controller,
    required this.day,
    this.isCurrentDay = true,
    this.showsDiscovery = false,
  });

  /// The engine's tone for the reading this ⓘ belongs to. The rotation only
  /// picks a sentence from this tone's pool; it never chooses the tone.
  final String? level;

  final DailyEnergyInsightController controller;

  /// The local date the insight belongs to — today on Home, and the reading's
  /// own date on a Result, so a Result left open past midnight keeps pointing
  /// at the day it was read for.
  final String day;

  /// Whether [day] is the reader's current local date. Only then can there be
  /// anything "new today" to announce.
  final bool isCurrentDay;

  /// Home only: the one-shot orbit and the one-time coach mark. A Result shows
  /// the same icon without competing for attention.
  final bool showsDiscovery;

  @override
  State<DailyEnergyInfoButton> createState() => _DailyEnergyInfoButtonState();
}

class _DailyEnergyInfoButtonState extends State<DailyEnergyInfoButton>
    with SingleTickerProviderStateMixin {
  static const _orbitDuration = Duration(milliseconds: 1300);
  static const _coachMarkDuration = Duration(seconds: 6);

  final _portal = OverlayPortalController();
  final _coachPortal = OverlayPortalController();
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: _orbitDuration,
  );

  ScrollPosition? _scrollPosition;
  Timer? _coachTimer;

  /// Kept here rather than read back off the controllers: they reject being
  /// asked to hide something they never showed, and the icon's own appearance
  /// has to follow this anyway.
  var _open = false;
  var _coachOpen = false;

  /// The sentence the reader opened. Dealt on the first open of this date and
  /// level, then fixed.
  String? _message;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.ensureLoaded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A tab pinned to a scrolled-away icon would be pointing at nothing, so it
    // closes when the page moves under it.
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scrollPosition) {
      _scrollPosition?.removeListener(_close);
      _scrollPosition = position?..addListener(_close);
    }
    _runDiscovery();
  }

  @override
  void didUpdateWidget(DailyEnergyInfoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      widget.controller.ensureLoaded();
    }
    // The tone or the date moved under us, so whatever is open belongs to the
    // old one.
    if (oldWidget.level != widget.level || oldWidget.day != widget.day) {
      _message = null;
      _setOpen(false);
    }
    _runDiscovery();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollPosition?.removeListener(_close);
    _coachTimer?.cancel();
    _orbit.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    _runDiscovery();
  }

  bool get _available => hasDailyEnergyInsight(widget.level);

  /// Whether this date and level still has an unopened insight. Only a current
  /// day can: a Result for a past date never announces "new today".
  bool get _unread =>
      _available &&
      widget.isCurrentDay &&
      widget.controller.isUnread(widget.day, widget.level!);

  /// Runs [action] now, or after this frame when a build is in progress.
  ///
  /// Showing or hiding an [OverlayPortal] — and calling setState — during the
  /// build phase is illegal, and discovery is driven from lifecycle callbacks
  /// that can land there.
  void _afterFrame(VoidCallback action) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });
    } else {
      action();
    }
  }

  /// Starts the one-shot orbit and the one-time coach mark, at most once each.
  void _runDiscovery() => _afterFrame(_startDiscovery);

  void _startDiscovery() {
    if (!widget.showsDiscovery || !_unread || _open) return;
    final controller = widget.controller;

    // Reduced motion keeps the static gold mark and skips the movement. The
    // day is left unmarked so the orbit can still play if that setting is
    // turned off later the same day.
    if (controller.shouldPlayOrbit(widget.day) &&
        _orbit.status == AnimationStatus.dismissed &&
        !MediaQuery.of(context).disableAnimations) {
      _orbit.forward();
      controller.markOrbitPlayed(widget.day);
    }

    if (!controller.coachMarkShown && !_coachOpen) {
      setState(() => _coachOpen = true);
      _coachPortal.show();
      controller.markCoachMarkShown();
      _coachTimer = Timer(_coachMarkDuration, _dismissCoachMark);
    }
  }

  void _dismissCoachMark() {
    _coachTimer?.cancel();
    _coachTimer = null;
    if (!mounted || !_coachOpen) return;
    _afterFrame(() {
      if (!_coachOpen) return;
      setState(() => _coachOpen = false);
      _coachPortal.hide();
    });
  }

  void _close() => _setOpen(false);

  void _setOpen(bool value) {
    if (_open == value || !mounted) return;
    _afterFrame(() {
      if (_open == value) return;
      setState(() => _open = value);
      value ? _portal.show() : _portal.hide();
    });
  }

  Future<void> _toggle() async {
    if (_open) {
      _setOpen(false);
      return;
    }
    _dismissCoachMark();
    final message = await widget.controller.open(widget.day, widget.level!);
    if (!mounted || message == null) return;
    setState(() => _message = message);
    _setOpen(true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();

    final unread = _unread;

    return OverlayPortal(
      controller: _coachPortal,
      overlayChildBuilder: (_) => _anchoredOverlay(
        // No barrier: the coach mark is an aside, and must not swallow a tap
        // meant for the page behind it.
        barrier: false,
        onBarrierTap: _dismissCoachMark,
        build: (placement, pointerOffset) => _InfoTab(
          onTap: _dismissCoachMark,
          message: 'A new energy insight awaits here each day.',
          placement: placement,
          pointerOffset: pointerOffset,
          textKey: const Key('daily_energy_coach_mark'),
          accent: CompassColors.gold,
        ),
      ),
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (_) => _anchoredOverlay(
          onBarrierTap: _close,
          build: (placement, pointerOffset) => _InfoTab(
            message: _message ?? '',
            placement: placement,
            pointerOffset: pointerOffset,
            textKey: const Key('daily_energy_note'),
          ),
        ),
        // The tooltip is the screen-reader label: IconButton builds its own
        // semantics node from it, so an extra Semantics wrapper here would be
        // dropped rather than merged.
        child: IconButton(
          key: const Key('daily_energy_info_button'),
          tooltip: _open
              ? 'Hide what today’s energy means'
              : (unread
                    ? 'New energy insight today'
                    : 'Read today’s energy insight'),
          onPressed: _toggle,
          icon: _Glyph(open: _open, unread: unread, orbit: _orbit),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }

  /// Places an anchored tab in the empty band to the right of the icon, which
  /// is where the energy row has room to spare, and only drops it under the
  /// icon when that band is too narrow to read in — a phone in portrait,
  /// mostly.
  ///
  /// Either way it is clamped inside the screen, so it can never hang off an
  /// edge.
  Widget _anchoredOverlay({
    required VoidCallback onBarrierTap,
    bool barrier = true,
    required Widget Function(_TabPlacement placement, double pointerOffset)
    build,
  }) {
    final anchor = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (anchor == null || overlay == null || !anchor.attached) {
      return const SizedBox.shrink();
    }

    const margin = 12.0, gap = 8.0, maxWidth = 270.0;
    // Narrower than this and the sentence turns into a ragged column, so the
    // tab is better off below the icon at full width.
    const minSideBand = 150.0;

    final screen = overlay.size;
    final origin = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final anchorRight = origin.dx + anchor.size.width;
    final sideBand = screen.width - anchorRight - gap - margin;

    final barriers = <Widget>[
      if (barrier)
        Positioned.fill(
          child: GestureDetector(
            key: const Key('daily_energy_note_barrier'),
            behavior: HitTestBehavior.translucent,
            onTap: onBarrierTap,
          ),
        ),
    ];

    if (sideBand >= minSideBand) {
      final width = math.min(maxWidth, sideBand);
      final anchorBottom = origin.dy + anchor.size.height;
      return Stack(
        children: [
          ...barriers,
          // The tab's bottom edge rests on the icon's, so it grows upward into
          // the empty band beside the card's heading instead of down over the
          // signal tiles. Nothing below the energy row is ever covered.
          Positioned(
            left: anchorRight + gap,
            top: margin,
            bottom: screen.height - anchorBottom,
            width: width,
            child: Align(
              alignment: Alignment.bottomLeft,
              // Lifts the pointer off the bottom edge to the icon's centre.
              child: build(_TabPlacement.right, anchor.size.height / 2),
            ),
          ),
        ],
      );
    }

    final width = math.min(maxWidth, screen.width - margin * 2);
    final left = (origin.dx + anchor.size.width / 2 - width / 2)
        .clamp(margin, math.max(margin, screen.width - margin - width))
        .toDouble();
    final below = origin.dy + anchor.size.height + gap;
    final fitsBelow = screen.height - below >= 96;
    // Where the icon sits along the tab, so the pointer lands under it even
    // once the tab itself has been clamped sideways.
    final pointerDx = (origin.dx + anchor.size.width / 2 - left)
        .clamp(16.0, math.max(16.0, width - 16))
        .toDouble();
    final tab = build(
      fitsBelow ? _TabPlacement.below : _TabPlacement.above,
      pointerDx,
    );

    return Stack(
      children: [
        ...barriers,
        if (fitsBelow)
          Positioned(left: left, top: below, width: width, child: tab)
        else
          Positioned(
            left: left,
            bottom: screen.height - origin.dy + gap,
            width: width,
            child: tab,
          ),
      ],
    );
  }
}

/// The ⓘ itself: grey once read, soft gold with a dot while today's insight is
/// still unopened, and briefly circled by a thin ring the first time Home
/// shows an unread one.
///
/// The icon keeps its size, position and 40dp tap target throughout; the ring
/// and the dot are painted inside the same box rather than added to the row.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.open, required this.unread, required this.orbit});

  final bool open;
  final bool unread;
  final Animation<double> orbit;

  @override
  Widget build(BuildContext context) {
    final colour = open
        ? CompassColors.secondary
        : (unread ? CompassColors.gold : CompassColors.muted);

    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: orbit,
            builder: (context, child) =>
                orbit.value == 0 || orbit.status == AnimationStatus.completed
                ? const SizedBox.shrink()
                : CustomPaint(
                    key: const Key('daily_energy_orbit'),
                    size: const Size(22, 22),
                    painter: _OrbitPainter(progress: orbit.value),
                  ),
          ),
          Icon(
            open ? Icons.info_rounded : Icons.info_outline_rounded,
            size: 18,
            color: colour,
          ),
          if (unread && !open)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                key: const Key('daily_energy_unread_dot'),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CompassColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One thin gold arc travelling once around the icon, then gone.
class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 0.6,
    );
    // Fades in and back out, so the ring never simply stops mid-stroke.
    final fade = math.sin(progress * math.pi);
    canvas.drawArc(
      rect,
      progress * 2 * math.pi - math.pi / 2,
      math.pi / 2,
      false,
      Paint()
        ..color = CompassColors.gold.withValues(alpha: 0.75 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Which side of the icon the tab hangs off, and therefore where its pointer
/// goes.
enum _TabPlacement { right, below, above }

class _InfoTab extends StatelessWidget {
  const _InfoTab({
    required this.message,
    required this.placement,
    required this.textKey,
    this.pointerOffset = 16,
    this.accent,
    this.onTap,
  });

  final String message;
  final _TabPlacement placement;
  final Key textKey;

  /// How far along the edge the pointer sits: from the tab's left edge when it
  /// is above or below the icon, and up from its bottom edge when it is beside
  /// it.
  final double pointerOffset;

  /// Border and text tint. The coach mark borrows gold so it reads as an
  /// invitation rather than as the insight itself.
  final Color? accent;

  /// Dismisses the tab when it is itself tapped. Only the coach mark uses it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bubble = Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CompassColors.raised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent ?? CompassColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            message,
            key: textKey,
            style: TextStyle(
              color: accent ?? CompassColors.secondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
      ),
    );

    if (placement == _TabPlacement.right) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: math.max(0, pointerOffset - 5)),
            child: CustomPaint(
              size: const Size(5, 10),
              painter: _PointerPainter(
                placement: _TabPlacement.right,
                accent: accent,
              ),
            ),
          ),
          Expanded(child: bubble),
        ],
      );
    }

    final pointer = Padding(
      padding: EdgeInsets.only(left: pointerOffset - 5),
      child: CustomPaint(
        size: const Size(10, 5),
        painter: _PointerPainter(placement: placement, accent: accent),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (placement == _TabPlacement.below) pointer,
        bubble,
        if (placement == _TabPlacement.above) pointer,
      ],
    );
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.placement, this.accent});

  final _TabPlacement placement;
  final Color? accent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    switch (placement) {
      // Beside the icon: the pointer is on the tab's left edge, aiming back
      // at it.
      case _TabPlacement.right:
        path
          ..moveTo(0, size.height / 2)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height);
      case _TabPlacement.below:
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height);
      case _TabPlacement.above:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas
      ..drawPath(path, Paint()..color = CompassColors.raised)
      ..drawPath(
        path,
        Paint()
          ..color = accent ?? CompassColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) =>
      oldDelegate.placement != placement || oldDelegate.accent != accent;
}
