import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../analytics/analytics_service.dart';
import '../services/ad_service.dart';
import 'analytics_consent_tile.dart';
import '../localized_presentation.dart';
import '../theme.dart';

/// Shows the Responsible Use & Safety boundaries modal.
///
/// Returns `true` if the user confirmed agreement, or `false`/`null` if dismissed.
Future<bool> showResponsibleUseSheet(
  BuildContext context, {
  bool isFirstTimeAcknowledgement = false,
  AnalyticsService analytics = const NoopAnalyticsService(),
  AdService ads = const NoOpAdService(),
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ResponsibleUseSheet(
      isFirstTimeAcknowledgement: isFirstTimeAcknowledgement,
      analytics: analytics,
      ads: ads,
    ),
  );
  return result ?? false;
}

/// The safety boundaries, and the one-time acknowledgement before a first
/// reading.
///
/// Country-neutral by design. There are no telephone numbers here: an
/// emergency number that is right in one country is dangerously wrong in
/// another, and this app is used in seven languages across many more countries
/// than that. It points at local emergency services and a local helpline
/// instead, and names neither.
///
/// It also makes no age or liability claim. "You must be at least 13" and "you
/// assume 100% personal responsibility" were removed rather than translated:
/// the first is a jurisdictional question this prototype has not answered, and
/// the second is a legal assertion no copy here is in a position to make.
class ResponsibleUseSheet extends StatefulWidget {
  const ResponsibleUseSheet({
    super.key,
    this.isFirstTimeAcknowledgement = false,
    this.analytics = const NoopAnalyticsService(),
    this.ads = const NoOpAdService(),
  });

  final bool isFirstTimeAcknowledgement;
  final AnalyticsService analytics;
  final AdService ads;

  @override
  State<ResponsibleUseSheet> createState() => _ResponsibleUseSheetState();
}

class _ResponsibleUseSheetState extends State<ResponsibleUseSheet>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();

  /// Whether the reader has had the whole policy on screen.
  ///
  /// Latched: once it is true it stays true. Re-locking somebody who has
  /// already read everything because they rotated the phone would be hostile,
  /// and the thing worth preventing is a button that can never be reached.
  var _reachedEnd = false;

  /// Whether the sheet currently has content below the fold to scroll through.
  var _hasOverflowContent = false;

  /// Whether initial scroll metrics have been measured at least once.
  var _hasMeasuredMetrics = false;

  /// Whether the initial gentle chevron bounce on the cue pill has run.
  var _playedInitialCueBounce = false;

  /// Whether the "scroll to the end" hint is showing.
  var _showHint = false;

  /// Finite entrance bounce for the scroll cue pill chevron so real users
  /// notice it without spinning an infinite ticker that would stall tests.
  late final AnimationController _cueBounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  /// How close to the bottom counts as the bottom.
  ///
  /// Scroll offsets are doubles produced by layout arithmetic, so `pixels ==
  /// maxScrollExtent` is not reliably true even when the reader is visibly at
  /// the end — a fraction of a logical pixel would otherwise leave the button
  /// locked forever with nothing left to scroll.
  static const double _endSlack = 2;

  @override
  void dispose() {
    _cueBounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// True when there is nothing left to read below the fold.
  bool _isAtEnd(ScrollMetrics metrics) =>
      // Content that fits has no scroll extent at all, which is the "already
      // fits" case: there is nothing to scroll, so nothing to wait for.
      metrics.maxScrollExtent <= _endSlack ||
      metrics.pixels >= metrics.maxScrollExtent - _endSlack;

  void _triggerCueBounce() {
    if (!mounted || MediaQuery.of(context).disableAnimations) return;
    _cueBounceController.forward(from: 0);
  }

  void _updateScrollMetrics(ScrollMetrics metrics) {
    final hasOverflow = metrics.maxScrollExtent > _endSlack;
    final atEnd = _isAtEnd(metrics);
    final nextReachedEnd = _reachedEnd || atEnd;
    if (_hasMeasuredMetrics &&
        hasOverflow == _hasOverflowContent &&
        nextReachedEnd == _reachedEnd) {
      return;
    }
    setState(() {
      _hasMeasuredMetrics = true;
      _hasOverflowContent = hasOverflow;
      if (nextReachedEnd) {
        _reachedEnd = true;
        _showHint = false;
      }
    });
    if (widget.isFirstTimeAcknowledgement &&
        hasOverflow &&
        !nextReachedEnd &&
        !_playedInitialCueBounce) {
      _playedInitialCueBounce = true;
      _triggerCueBounce();
    }
  }

  /// Re-measures after the frame that laid the content out.
  ///
  /// Scheduled from `build`, so it re-runs after anything that can change how
  /// much there is to scroll — a resize, a rotation, a text-scale change, a
  /// language with longer copy — without needing to know which of those it
  /// was.
  void _scheduleRemeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _updateScrollMetrics(_scrollController.position);
    });
  }

  Future<void> _scrollDownCueStep() async {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final step = (position.viewportDimension * 0.72).clamp(180.0, 420.0);
    final target = (position.pixels + step).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _hideHint();
    if (MediaQuery.of(context).disableAnimations) {
      _scrollController.jumpTo(target);
      return;
    }
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _hideHint() {
    if (!_showHint) return;
    setState(() => _showHint = false);
  }

  /// The locked button's only effect: say why it is locked.
  ///
  /// Deliberately not a disabled button. A disabled control gives a reader no
  /// explanation and no way to ask for one, and on a screen whose whole point
  /// is that the policy was read, "nothing happens" is the worst answer.
  void _explainWhyLocked() {
    setState(() => _showHint = true);
    _triggerCueBounce();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;
    final gated = widget.isFirstTimeAcknowledgement && !_reachedEnd;
    final showScrollCue = gated && _hasOverflowContent;
    if (!_hasMeasuredMetrics || gated) {
      _scheduleRemeasure();
    }

    return GestureDetector(
      // A tap anywhere that is not the button dismisses the hint. Translucent
      // so the content underneath still receives its own taps and scrolls.
      behavior: HitTestBehavior.translucent,
      onTap: _hideHint,
      child: Container(
        key: const Key('responsible_use_sheet'),
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: CompassColors.raised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: CompassColors.line),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 32, spreadRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  NotificationListener<ScrollMetricsNotification>(
                    // Fires when the amount there is to scroll changes without
                    // the reader scrolling — a rotation, a text-scale change —
                    // which is the case `_scheduleRemeasure` would otherwise
                    // have to guess at.
                    onNotification: (notification) {
                      _updateScrollMetrics(notification.metrics);
                      return false;
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        // Starting to scroll is an answer to the hint, so it goes.
                        if (notification is ScrollStartNotification)
                          _hideHint();
                        _updateScrollMetrics(notification.metrics);
                        return false;
                      },
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbVisibility: _hasOverflowContent,
                        trackVisibility: _hasOverflowContent,
                        thickness: 4.5,
                        radius: const Radius.circular(99),
                        crossAxisMargin: 5,
                        mainAxisMargin: 6,
                        thumbColor: CompassColors.gold.withValues(alpha: 0.78),
                        trackColor: Colors.white.withValues(alpha: 0.05),
                        trackBorderColor: Colors.transparent,
                        child: SingleChildScrollView(
                          primary: false,
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            22,
                            4,
                            22,
                            widget.isFirstTimeAcknowledgement ? 58 : 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Emblem icon
                              Center(
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.07),
                                    border: Border.all(
                                      color: CompassColors.gold.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    color: CompassColors.gold,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l10n.safetyHeading,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: CompassColors.gold,
                                      letterSpacing: trackingFor(context, 2.0),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.safetyTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.safetyIntro,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: CompassColors.secondary,
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 22),

                              // Guardrails header
                              Text(
                                l10n.prohibitedUses,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: CompassColors.coral,
                                      letterSpacing: trackingFor(context, 1.5),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 10),

                              // The seven boundaries. The order is fixed so a reader who
                              // has seen this before finds the same one in the same place
                              // whatever language they are reading it in.
                              _GuardrailTile(
                                icon: Icons.dangerous_rounded,
                                title: l10n.harmTitle,
                                detail: l10n.harmDetail,
                              ),
                              _GuardrailTile(
                                icon: Icons.directions_car_rounded,
                                title: l10n.navigationTitle,
                                detail: l10n.navigationDetail,
                              ),
                              _GuardrailTile(
                                icon: Icons.balance_rounded,
                                title: l10n.politicsTitle,
                                detail: l10n.politicsDetail,
                              ),
                              _GuardrailTile(
                                icon: Icons.local_hospital_rounded,
                                title: l10n.medicalTitle,
                                detail: l10n.medicalDetail,
                              ),
                              _GuardrailTile(
                                icon: Icons.gavel_rounded,
                                title: l10n.legalTitle,
                                detail: l10n.legalDetail,
                              ),
                              _GuardrailTile(
                                icon: Icons.trending_down_rounded,
                                title: l10n.financeTitle,
                                detail: l10n.financeDetail,
                              ),
                              _GuardrailTile(
                                icon: Icons.people_outline_rounded,
                                title: l10n.consentTitle,
                                detail: l10n.consentDetail,
                              ),

                              const SizedBox(height: 16),

                              Container(
                                key: const Key('important_limits'),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          size: 16,
                                          color: CompassColors.gold,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.importantLimitsHeading,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: CompassColors.gold,
                                                  letterSpacing: trackingFor(
                                                    context,
                                                    1.2,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.importantLimitsBody,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.white70,
                                            height: 1.5,
                                          ),
                                    ),
                                    if (!widget.isFirstTimeAcknowledgement) ...[
                                      const Divider(
                                        height: 18,
                                        color: Colors.white12,
                                      ),
                                      Text(
                                        l10n.crisisSupport,
                                        key: const Key('crisis_support'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: CompassColors.blueLight,
                                              height: 1.45,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!widget.isFirstTimeAcknowledgement)
                                AnalyticsConsentTile(
                                  analytics: widget.analytics,
                                ),
                              if (!widget.isFirstTimeAcknowledgement &&
                                  widget.ads.privacyOptionsRequired)
                                TextButton.icon(
                                  key: const Key('ad_privacy_options'),
                                  onPressed: () =>
                                      widget.ads.showPrivacyOptions(),
                                  icon: const Icon(Icons.privacy_tip_outlined),
                                  label: Text(l10n.adPrivacyOptions),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 12,
                    bottom: 0,
                    child: IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: showScrollCue
                            ? Container(
                                key: const Key('safety_scroll_bottom_fade'),
                                height: 62,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.65, 1.0],
                                    colors: [
                                      CompassColors.raised.withValues(alpha: 0),
                                      CompassColors.raised.withValues(
                                        alpha: 0.90,
                                      ),
                                      CompassColors.raised,
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 10,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: showScrollCue
                          ? Center(
                              key: const Key('safety_scroll_cue_pill_wrap'),
                              child: _ScrollCuePill(
                                key: const Key('safety_scroll_cue_pill'),
                                label: l10n.safetyScrollCuePill,
                                bounceAnimation: _cueBounceController,
                                onTap: _scrollDownCueStep,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            // Pinned bottom action bar
            Container(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
              decoration: const BoxDecoration(
                color: CompassColors.raised,
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: SafeArea(
                top: false,
                child: widget.isFirstTimeAcknowledgement
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Above the button, where a reader looking at the
                          // button will already be looking.
                          if (_showHint)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Semantics(
                                // One node carrying both the words and the
                                // flag. `Semantics(liveRegion: true)` wrapped
                                // around a Text produces two nodes — the words
                                // on one, the flag on the other — and a screen
                                // reader announces neither as an update.
                                // `container: true` is load-bearing: without
                                // it `Semantics` annotates the parent's node
                                // instead of making one, so the live region
                                // ends up covering the fixed line below as
                                // well and a screen reader re-announces that
                                // line every time the hint appears.
                                container: true,
                                liveRegion: true,
                                label: l10n.safetyScrollToContinue,
                                excludeSemantics: true,
                                child: Text(
                                  l10n.safetyScrollToContinue,
                                  key: const Key('safety_scroll_hint'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: CompassColors.gold,
                                        height: 1.35,
                                      ),
                                ),
                              ),
                            ),
                          _AgreeButton(
                            gated: gated,
                            label: l10n.acknowledge,
                            lockedHint: l10n.safetyScrollToContinue,
                            onLockedTap: _explainWhyLocked,
                            onAgree: () => Navigator.of(context).pop(true),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.acknowledgementOnce,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: CompassColors.muted,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      )
                    : OutlinedButton(
                        key: const Key('close_safety_sheet'),
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(l10n.closeAction),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The acknowledgement button, in its locked and unlocked forms.
///
/// Locked, it is still a real tappable control — that tap is the only way to
/// be told why it is locked — but its semantics are *replaced* rather than
/// wrapped. Wrapping leaves the button's own node reporting `enabled: true`
/// beside an ancestor node saying otherwise, and a screen reader reads the
/// button's. Replacing them makes what assistive technology hears match what
/// the control looks like and what it actually does.
class _AgreeButton extends StatelessWidget {
  const _AgreeButton({
    required this.gated,
    required this.label,
    required this.lockedHint,
    required this.onLockedTap,
    required this.onAgree,
  });

  final bool gated;
  final String label;
  final String lockedHint;
  final VoidCallback onLockedTap;
  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      key: const Key('agree_safety_boundaries'),
      style: gated
          ? FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              foregroundColor: CompassColors.muted,
            )
          : null,
      onPressed: gated ? onLockedTap : onAgree,
      child: Text(label, textAlign: TextAlign.center),
    );
    if (!gated) return button;
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      hint: lockedHint,
      onTap: onLockedTap,
      excludeSemantics: true,
      child: button,
    );
  }
}

class _GuardrailTile extends StatelessWidget {
  const _GuardrailTile({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CompassColors.coral.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: CompassColors.coral),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Safety copy wraps rather than truncating, at any text
                  // scale and in any language: a boundary the reader cannot
                  // finish reading is not a boundary.
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CompassColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CompassColors.secondary,
                      height: 1.35,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating celestial gold pill reminding first-time readers to scroll down.
class _ScrollCuePill extends StatelessWidget {
  const _ScrollCuePill({
    super.key,
    required this.label,
    required this.bounceAnimation,
    required this.onTap,
  });

  final String label;
  final Animation<double> bounceAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: CompassColors.deep.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: CompassColors.gold.withValues(alpha: 0.72),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: CompassColors.gold.withValues(alpha: 0.22),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: bounceAnimation,
                builder: (context, child) {
                  final dy = reduceMotion
                      ? 0.0
                      : math.sin(bounceAnimation.value * math.pi * 6).abs() *
                            3.0;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.keyboard_double_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFFFFE4A3),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFFFE4A3),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
