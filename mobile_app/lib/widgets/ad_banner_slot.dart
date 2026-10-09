import 'package:flutter/material.dart';

import '../theme.dart';

/// A dedicated, isolated bottom slot for AdMob banner ads.
///
/// Designed to satisfy Google AdMob Content Overlap policy:
/// - Never positioned as a floating overlay above scrollable viewports.
/// - Occupies a fixed-height layout slot (50–52dp) outside scroll views.
/// - Guarantees zero overlap with interactive buttons or disclaimers.
class AdBannerSlot extends StatelessWidget {
  const AdBannerSlot({
    super.key,
    this.height = 50.0,
    this.advertiserName,
    this.title,
    this.callToAction,
    this.onTap,
  });

  final double height;
  final String? advertiserName;
  final String? title;
  final String? callToAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'vi';
    final (resolvedTitle, resolvedCta) = switch (lang) {
      'en' => ('Lucky feng shui crystal bracelet', 'View now'),
      'ja' => ('幸運の天然石ブレスレット', '今すぐ見る'),
      'ko' => ('행운의 천연 원석 팔찌', '바로보기'),
      'zh' => ('开运风水水晶手串', '立即查看'),
      'es' => ('Pulsera de piedra de la suerte', 'Ver ahora'),
      'th' => ('กำไลหินมงคลนำโชค', 'ดูเลย'),
      'hi' => ('शुभ रत्न ब्रेसलेट', 'अभी देखें'),
      _ => ('Vòng đá phong thủy may mắn', 'Xem ngay'),
    };
    final displayAdvertiser = advertiserName ?? 'Astra Store';
    final displayTitle = title ?? resolvedTitle;
    final displayCta = callToAction ?? resolvedCta;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF091222),
        border: Border(
          top: BorderSide(
            color: CompassColors.blueLight.withValues(alpha: 0.18),
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // "AD" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: CompassColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: CompassColors.gold.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: const Text(
              'AD',
              style: TextStyle(
                color: CompassColors.gold,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Ad description
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$displayAdvertiser: $displayTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Call to action button
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.8,
                ),
              ),
              child: Text(
                displayCta,
                style: const TextStyle(
                  color: CompassColors.blueLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
