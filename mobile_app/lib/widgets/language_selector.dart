import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../data/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// The always-visible globe and current language, shown on the welcome screen
/// above the profile step and again on Home.
///
/// Deliberately not a startup popup and not a screen of its own: a reader who
/// wants English — the first-launch default — never has to answer anything,
/// and a reader who wants another language can see at a glance that one is
/// available and change it whenever they like.
class LanguageButton extends StatelessWidget {
  const LanguageButton({
    super.key,
    required this.controller,
    this.compact = false,
  });

  final LocaleController controller;

  /// Home's version: the globe alone, matching the other header controls.
  final bool compact;

  Future<void> _open(BuildContext context) =>
      showLanguageSheet(context, controller);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = controller.locale;

    if (compact) {
      return IconButton.filledTonal(
        key: const Key('language_button'),
        tooltip: '${l10n.changeLanguage} · ${current.nativeName}',
        onPressed: () => _open(context),
        icon: const Icon(Icons.language_rounded, size: 20),
      );
    }

    return Semantics(
      button: true,
      // The chosen language is part of the label rather than a separate node,
      // so a screen reader announces what tapping this would change.
      label: '${l10n.languageSetting}: ${current.nativeName}',
      child: TextButton.icon(
        key: const Key('language_button'),
        onPressed: () => _open(context),
        style: TextButton.styleFrom(
          foregroundColor: CompassColors.secondary,
          // Android's minimum accessible target, which the default dense
          // TextButton does not reach on its own.
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: CompassColors.line),
          ),
        ),
        icon: const Icon(Icons.language_rounded, size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The native name, never a translation of it: a reader looking for
            // their language has to recognise it without already reading the
            // current one.
            Flexible(
              child: Text(
                current.nativeName,
                key: const Key('language_button_label'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

/// The language bottom sheet: seven options, each in its own script.
Future<void> showLanguageSheet(
  BuildContext context,
  LocaleController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _LanguageSheet(controller: controller),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.controller});

  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('language_sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: CompassColors.raised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: CompassColors.line),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  l10n.chooseLanguage,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 12),
              for (final option in AppLocale.values)
                _LanguageOption(
                  option: option,
                  selected: option == controller.locale,
                  onTap: () {
                    // Persisting is the controller's business; closing is this
                    // sheet's. The switch itself repaints the page behind.
                    controller.select(option);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppLocale option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.nativeName,
      child: InkWell(
        key: Key('language_option_${option.tag}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.nativeName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? CompassColors.blueLight
                        : CompassColors.text,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: CompassColors.blueLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
