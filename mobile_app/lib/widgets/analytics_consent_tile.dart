import 'package:flutter/material.dart';

import '../analytics/analytics_service.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Optional and independent of the safety acknowledgement. No permission
/// dialog, required step or blocked navigation.
class AnalyticsConsentTile extends StatefulWidget {
  const AnalyticsConsentTile({
    super.key,
    required this.analytics,
    this.onEnabled,
  });
  final AnalyticsService analytics;
  final VoidCallback? onEnabled;
  @override
  State<AnalyticsConsentTile> createState() => _AnalyticsConsentTileState();
}

class _AnalyticsConsentTileState extends State<AnalyticsConsentTile> {
  bool _saveFailed = false;
  Future<void> _change(bool value) async {
    setState(() => _saveFailed = false);
    final saved = await widget.analytics.setEnabled(value);
    if (!mounted) return;
    setState(() => _saveFailed = !saved);
    if (saved && value) widget.onEnabled?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.analytics is NoopAnalyticsService)
      return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.analytics,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('analytics_consent_toggle'),
            contentPadding: EdgeInsets.zero,
            value: widget.analytics.enabled,
            onChanged: widget.analytics.busy ? null : _change,
            title: Text(
              l10n.analyticsConsentTitle,
              style: const TextStyle(fontSize: 13, color: CompassColors.text),
            ),
            subtitle: Text(
              l10n.analyticsConsentBody,
              style: const TextStyle(
                fontSize: 11,
                color: CompassColors.secondary,
              ),
            ),
          ),
          if (_saveFailed)
            Text(
              l10n.analyticsConsentSaveFailed,
              key: const Key('analytics_consent_error'),
              style: const TextStyle(fontSize: 12, color: CompassColors.coral),
            ),
        ],
      ),
    );
  }
}
