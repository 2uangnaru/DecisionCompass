import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../localized_presentation.dart';
import '../theme.dart';

/// Shows the Responsible Use & Safety boundaries modal.
///
/// Returns `true` if the user confirmed agreement, or `false`/`null` if dismissed.
Future<bool> showResponsibleUseSheet(
  BuildContext context, {
  bool isFirstTimeAcknowledgement = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ResponsibleUseSheet(
      isFirstTimeAcknowledgement: isFirstTimeAcknowledgement,
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
class ResponsibleUseSheet extends StatelessWidget {
  const ResponsibleUseSheet({
    super.key,
    this.isFirstTimeAcknowledgement = false,
  });

  final bool isFirstTimeAcknowledgement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Container(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
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
                          color: CompassColors.gold.withValues(alpha: 0.4),
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CompassColors.gold,
                      letterSpacing: trackingFor(context, 2.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.safetyTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.safetyIntro,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CompassColors.secondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Guardrails header
                  Text(
                    l10n.prohibitedUses,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: CompassColors.gold,
                                      letterSpacing: trackingFor(context, 1.2),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.importantLimitsBody,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70, height: 1.5),
                        ),
                        if (!isFirstTimeAcknowledgement) ...[
                          const Divider(height: 18, color: Colors.white12),
                          Text(
                            l10n.crisisSupport,
                            key: const Key('crisis_support'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: CompassColors.blueLight,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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
              child: isFirstTimeAcknowledgement
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          key: const Key('agree_safety_boundaries'),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            l10n.acknowledge,
                            textAlign: TextAlign.center,
                          ),
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
