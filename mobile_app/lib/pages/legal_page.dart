import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/ios_platform_bridge.dart';

enum LegalDocument { privacy, terms }

/// Public URLs supplied by the owner, checked before a store archive.
class ReleaseLinks {
  static const privacy = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const terms = String.fromEnvironment('TERMS_OF_USE_URL');
  static const support = String.fromEnvironment('SUPPORT_URL');

  static Uri? https(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }
}

/// The policy is readable even in an account-free demo without hosted URLs.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.document});
  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final privacy = document == LegalDocument.privacy;
    final published = ReleaseLinks.https(
      privacy ? ReleaseLinks.privacy : ReleaseLinks.terms,
    );
    final support = ReleaseLinks.https(ReleaseLinks.support);
    return Scaffold(
      appBar: AppBar(
        title: Text(privacy ? l10n.legalPrivacy : l10n.legalTerms),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                privacy ? l10n.legalPrivacyBody : l10n.legalTermsBody,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 20),
              if (published != null)
                TextButton.icon(
                  onPressed: () => openLegalLink(context, published),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.legalPublishedPage),
                ),
              if (support != null)
                TextButton.icon(
                  onPressed: () => openLegalLink(context, support),
                  icon: const Icon(Icons.help_outline),
                  label: Text(l10n.legalSupport),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openLegalLink(BuildContext context, Uri uri) async {
  try {
    await const IOSPlatformBridge().openWebPage(uri);
  } catch (_) {
    if (context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).tryAgain)),
      );
    }
  }
}

/// iOS-only additions; the approved Android screens retain their layout.
class IOSLegalLinks extends StatelessWidget {
  const IOSLegalLinks({super.key});
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS)
      return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final document in LegalDocument.values)
          TextButton(
            key: ValueKey('legal_${document.name}'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LegalPage(document: document),
              ),
            ),
            child: Text(
              document == LegalDocument.privacy
                  ? l10n.legalPrivacy
                  : l10n.legalTerms,
            ),
          ),
        if (ReleaseLinks.https(ReleaseLinks.support) case final Uri uri)
          TextButton(
            onPressed: () => openLegalLink(context, uri),
            child: Text(l10n.legalSupport),
          ),
      ],
    );
  }
}
