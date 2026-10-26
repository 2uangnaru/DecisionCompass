import 'package:flutter/material.dart';

import '../analytics/analytics_service.dart';
import '../services/ad_runtime.dart';
import '../services/banner_ad.dart';
import '../services/banner_ad_controller.dart';

/// An anchored layout slot, never an overlay or a fake house advertisement.
/// Its route must be current, the app resumed and SDK consent settled to show.
class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({
    super.key,
    required this.ads,
    required this.placement,
    this.analytics = const NoopAnalyticsService(),
  });
  final AdService ads;
  final BannerPlacement placement;
  final AnalyticsService analytics;

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAdController? _controller;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    final backend = widget.ads.banners;
    if (backend == null) return;
    _controller = BannerAdController(
      ads: widget.ads,
      backend: backend,
      placement: widget.placement,
      analytics: widget.analytics,
    );
  }

  @override
  void didUpdateWidget(AdBannerSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads != widget.ads ||
        oldWidget.placement != widget.placement ||
        oldWidget.analytics != widget.analytics) {
      _controller?.dispose();
      _controller = null;
      _createController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    // This inherited aspect rebuilds on pushes, pops and modal sheets,
    // including while a covered Home route remains mounted.
    final active = ModalRoute.isCurrentOf(context) ?? true;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.floor()
            : 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && identical(controller, _controller)) {
            controller.configure(width: width, active: active);
          }
        });
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final ad = active && controller.width == width
                ? controller.visibleAd
                : null;
            // Reserve a small blank slot while unavailable, not fake ad copy.
            // The exact SDK size is established before displaying a creative;
            // loading, failure and automatic creative refresh don't resize it.
            final height = controller.size?.height.toDouble() ?? 50;
            return SizedBox(
              key: const Key('banner_layout_slot'),
              height: height + 8,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ad == null
                      ? null
                      : SizedBox(
                          width: ad.size.width.toDouble(),
                          height: ad.size.height.toDouble(),
                          child: ad.buildView(),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
