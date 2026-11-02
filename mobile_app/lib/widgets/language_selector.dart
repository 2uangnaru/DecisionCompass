import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// A prominent language selector card embedded directly in the onboarding welcome step.
///
/// Gives readers an unmissable, touch-friendly element on first launch so they know
/// what language is active and can switch with a single tap.
class WelcomeLanguageCard extends StatelessWidget {
  const WelcomeLanguageCard({
    super.key,
    required this.controller,
    this.compact = false,
  });

  final LocaleController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = controller.locale;

    return Semantics(
      button: true,
      label:
          '${l10n.languageSetting}: ${current.nativeName}. ${l10n.changeLanguage}',
      child: Material(
        key: const Key('language_button'),
        color: Colors.transparent,
        child: InkWell(
          key: const Key('welcome_language_card'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => showLanguageSheet(context, controller),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: CompassColors.raised.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CompassColors.gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: CompassColors.gold.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 32 : 38,
                  height: compact ? 32 : 38,
                  decoration: BoxDecoration(
                    color: CompassColors.gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CompassColors.gold.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    size: compact ? 17 : 20,
                    color: CompassColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.languageSetting,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: CompassColors.gold.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        current.nativeName,
                        key: const Key('language_button_label'),
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: CompassColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: compact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.changeLanguage,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CompassColors.gold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.unfold_more_rounded,
                        size: 14,
                        color: CompassColors.gold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  FocusScope.of(context).unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
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
                    // The sheet closes immediately — the switch itself
                    // repaints the page behind it, and waiting on storage
                    // before closing would make a slow write look like a
                    // stuck tap.
                    //
                    // The write is then awaited rather than dropped. An
                    // unawaited `select` whose save throws becomes an
                    // unhandled Future: the language changes, the failure is
                    // swallowed, and the reader finds their choice gone after
                    // a restart with nothing ever having said why.
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(context).pop();
                    unawaited(_selectAndReport(controller, option, messenger));
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

/// Applies the reader's choice, and says so when it could not be remembered.
///
/// The language stays switched either way. Reverting it would be a second
/// surprise on top of the first, and the choice is still correct for this
/// session — what is lost is only its survival across a restart, which is
/// exactly what the message says.
Future<void> _selectAndReport(
  LocaleController controller,
  AppLocale option,
  ScaffoldMessengerState messenger,
) async {
  try {
    await controller.select(option);
  } catch (_) {
    // Written in the language just chosen, which is the one now on screen.
    final l10n = lookupAppLocalizations(option.locale);
    messenger.showSnackBar(
      SnackBar(
        key: const Key('language_not_saved_notice'),
        duration: const Duration(seconds: 6),
        content: Text(l10n.languageNotSaved),
      ),
    );
  }
}
