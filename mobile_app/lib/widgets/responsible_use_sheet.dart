import 'package:flutter/material.dart';

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

class ResponsibleUseSheet extends StatelessWidget {
  const ResponsibleUseSheet({
    super.key,
    this.isFirstTimeAcknowledgement = false,
  });

  final bool isFirstTimeAcknowledgement;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Container(
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
                    'BOUNDARIES & RESPONSIBLE USE',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CompassColors.gold,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A Mirror for Everyday Moments',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'AstraCue provides symbolic perspectives derived from astronomical rhythms and personal cycles. '
                    'It is strictly provided for everyday self-reflection and entertainment. '
                    'Never use this app as a command, prophecy, or factual certainty.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CompassColors.secondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Guardrails header
                  Text(
                    'PROHIBITED USES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CompassColors.coral,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 7 Guardrail tiles
                  const _GuardrailTile(
                    icon: Icons.dangerous_rounded,
                    title: 'Harm & Self-Violence',
                    detail: 'Never use for self-harm, suicide, physical violence, or endangering yourself or anyone else.',
                  ),
                  const _GuardrailTile(
                    icon: Icons.directions_car_rounded,
                    title: 'Driving & Physical Navigation',
                    detail: 'Directions like LEFT / RIGHT and FORWARD / BACKWARD are symbolic polarities only. Never use them for traffic, driving, route-finding, or physical safety.',
                  ),
                  const _GuardrailTile(
                    icon: Icons.balance_rounded,
                    title: 'Politics & Social Conflicts',
                    detail: 'Never use for political campaigning, electoral decisions, civil unrest, or extremist activities.',
                  ),
                  const _GuardrailTile(
                    icon: Icons.local_hospital_rounded,
                    title: 'Health, Medical & Emergencies',
                    detail: 'Not a substitute for licensed physicians, prescription medicine, mental health therapy, or acute emergency response.',
                  ),
                  const _GuardrailTile(
                    icon: Icons.gavel_rounded,
                    title: 'Legal, Criminal & High-Stakes Contracts',
                    detail: 'Never use for criminal conduct, court litigation, testimony, or binding high-stakes legal contracts.',
                  ),
                  const _GuardrailTile(
                    icon: Icons.trending_down_rounded,
                    title: 'Financial Investments & Gambling',
                    detail: 'Not for speculative trading, borrowing, crypto bets, or gambling. You are solely responsible for your financial decisions.',
                  ),
                  const _GuardrailTile(
                    icon: Icons.people_outline_rounded,
                    title: 'Consent, Minors & Relationships',
                    detail: 'Never use to override another person’s consent or autonomy, or for child custody and minor guardianship decisions.',
                  ),

                  const SizedBox(height: 16),

                  // Legal Notice Box
                  Container(
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
                                'LEGAL DISCLAIMER & AGE NOTICE',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: CompassColors.gold,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Age Requirement: You must be at least 13 years of age (or the minimum legal age in your jurisdiction) to use this application.\n'
                          '• No Professional Advice: Content does not constitute medical, legal, or financial counsel.\n'
                          '• Assumption of Risk: You assume 100% personal responsibility for all actions and choices you make.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70, height: 1.5),
                        ),
                        if (!isFirstTimeAcknowledgement) ...[
                          const Divider(height: 18, color: Colors.white12),
                          Text(
                            'Crisis Support: If you or someone you know is in immediate emotional distress, contact emergency services (113/115 in Vietnam, 911/988 in the US) or a trusted helpline right away.',
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
                          child: const Text(
                            'I Understand & Agree to Boundaries',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This acknowledgement appears once before your first reading.',
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
                      child: const Text('Close'),
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
