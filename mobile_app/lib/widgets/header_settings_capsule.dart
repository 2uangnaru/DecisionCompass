import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'language_selector.dart';

/// A sleek horizontal sliding capsule for Home header action controls.
///
/// When collapsed, it occupies a compact 40x40 circle showing a 6-toothed
/// golden settings gear icon. When tapped, it expands smoothly to the left
/// into a 148px capsule, revealing the Language, Responsible Use, and History
/// action buttons with balanced spacing and concentric end cushioning.
class HeaderSettingsCapsule extends StatelessWidget {
  const HeaderSettingsCapsule({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onClose,
    required this.localeController,
    required this.onOpenResponsibleUse,
    required this.onOpenHistory,
  });

  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final LocaleController localeController;
  final VoidCallback onOpenResponsibleUse;
  final VoidCallback onOpenHistory;

  static const double collapsedWidth = 41.0;
  static const double expandedWidth = 160.0;
  static const double capsuleHeight = 41.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Absorb taps inside capsule so outer dismiss is not triggered
      child: AnimatedContainer(
        key: const Key('header_actions_capsule'),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: isOpen ? expandedWidth : collapsedWidth,
        height: capsuleHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xF5111B2E), // 96% opacity CompassColors.raised
          borderRadius: BorderRadius.circular(20.5),
          border: Border.all(
            color: isOpen
                ? CompassColors.gold.withValues(alpha: 0.85)
                : CompassColors.line,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isOpen ? 0.7 : 0.4),
              blurRadius: isOpen ? 16 : 8,
              offset: const Offset(0, 3),
            ),
            if (isOpen)
              BoxShadow(
                color: CompassColors.gold.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerRight,
          clipBehavior: Clip.none,
          children: [
            // 3 Action Buttons (🌐, 🛡️, 📜) sliding to the left of the gear
            Positioned(
              right: 44,
              top: 4,
              bottom: 4,
              child: AnimatedSlide(
                offset: isOpen ? Offset.zero : const Offset(0.18, 0),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: isOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: IgnorePointer(
                    ignoring: !isOpen,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CapsuleIconButton(
                          key: const Key('language_button'),
                          tooltip:
                              '${l10n.changeLanguage} · ${localeController.locale.nativeName}',
                          icon: const Icon(Icons.language_rounded, size: 22),
                          onPressed: () {
                            onClose();
                            showLanguageSheet(context, localeController);
                          },
                        ),
                        const SizedBox(width: 5),
                        _CapsuleIconButton(
                          key: const Key('home_responsible_use_button'),
                          tooltip: l10n.responsibleUse,
                          icon: const Icon(Icons.shield_outlined, size: 22),
                          onPressed: () {
                            onClose();
                            onOpenResponsibleUse();
                          },
                        ),
                        const SizedBox(width: 5),
                        _CapsuleIconButton(
                          key: const Key('home_history_button'),
                          tooltip: l10n.history,
                          icon: const Icon(Icons.history_rounded, size: 22),
                          onPressed: () {
                            onClose();
                            onOpenHistory();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 6-Toothed Settings Gear Button (⚙️) fixed at the far right (no inner circular border)
            Positioned(
              right: 3,
              top: 3,
              bottom: 3,
              child: _SettingsGearButton(
                isOpen: isOpen,
                onPressed: onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapsuleIconButton extends StatelessWidget {
  const _CapsuleIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 33,
      height: 33,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: const Color(0xD91A2943), // 85% CompassColors.glass
          shape: CircleBorder(
            side: BorderSide(
              color: CompassColors.line.withValues(alpha: 0.7),
              width: 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: IconTheme(
              data: const IconThemeData(
                color: CompassColors.secondary,
                size: 22,
              ),
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGearButton extends StatelessWidget {
  const _SettingsGearButton({
    required this.isOpen,
    required this.onPressed,
  });

  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      height: 35,
      child: Tooltip(
        message: isOpen
            ? (Localizations.localeOf(context).languageCode == 'vi'
                ? 'Thu gọn'
                : 'Collapse')
            : (Localizations.localeOf(context).languageCode == 'vi'
                ? 'Cài đặt'
                : 'Settings'),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('home_settings_button'),
            onTap: onPressed,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: isOpen ? math.pi : 0.0,
                ),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, angle, child) {
                  return Transform.rotate(
                    angle: angle,
                    child: child,
                  );
                },
                child: Transform.translate(
                  offset: const Offset(1.0, 0.0),
                  child: const Icon(
                    Icons.settings_rounded,
                    size: 25,
                    color: CompassColors.secondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
