import 'package:flutter/material.dart';

import '../theme.dart';

/// Shows the Monetization Unlock Bottom Sheet for Option 1.
///
/// Gives the user a transparent, voluntary choice:
/// 1. Wait for the free countdown (e.g. 02:15:34) to automatically expire.
/// 2. Watch a rewarded video ad (~30s) to unlock a reading immediately,
///    preserving the active free cooldown timer untouched.
Future<bool?> showMonetizationUnlockSheet(
  BuildContext context, {
  String remainingTime = '02:15:34',
  VoidCallback? onWatchAd,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => MonetizationUnlockSheet(
      remainingTime: remainingTime,
      onWatchAd: onWatchAd,
    ),
  );
}

class MonetizationUnlockSheet extends StatelessWidget {
  const MonetizationUnlockSheet({
    super.key,
    this.remainingTime = '02:15:34',
    this.onWatchAd,
  });

  final String remainingTime;
  final VoidCallback? onWatchAd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E182A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: CompassColors.gold.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            spreadRadius: 10,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle pill
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Header badge & title
            Text(
              'NHỊP ĐIỆU PHÂN TÍCH',
              style: TextStyle(
                color: CompassColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Năng Lượng Đang Lắng Đọng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Trực giác cần thời gian tĩnh lặng giữa các lần hỏi. Bạn có thể kiên nhẫn chờ hoặc mở ngay bằng 1 video ngắn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CompassColors.secondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: Natural Wait / Cooldown Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF14233C).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: CompassColors.line,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text('⏳', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tự động hồi lượt miễn phí sau:',
                          style: TextStyle(
                            color: CompassColors.secondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remainingTime,
                          style: const TextStyle(
                            color: CompassColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Không tốn phí',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Watch Rewarded Ad (Immediate Unlock)
            InkWell(
              onTap: () {
                Navigator.of(context).pop(true);
                onWatchAd?.call();
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2477C9),
                      Color(0xFF4EB3E8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2477C9).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '🎬 XEM 1 VIDEO NGẮN (~30S)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'MỞ NGAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PHÂN TÍCH NGAY BÂY GIỜ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✦ Đồng hồ đếm ngược $remainingTime của bạn vẫn giữ nguyên vẹn.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dismiss Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Tôi sẽ chờ lượt miễn phí',
                style: TextStyle(
                  color: CompassColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
