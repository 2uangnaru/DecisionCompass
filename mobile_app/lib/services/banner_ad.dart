import 'package:flutter/widgets.dart';

enum BannerPlacement { home, reveal }

@immutable
class BannerSize {
  const BannerSize(this.width, this.height);
  final int width;
  final int height;
}

/// Native callbacks, without SDK errors, IDs or arbitrary server text.
class BannerCallbacks {
  const BannerCallbacks({
    required this.loaded,
    required this.failed,
    required this.impression,
    required this.clicked,
    required this.opened,
    required this.closed,
    required this.paid,
  });
  final VoidCallback loaded, failed, impression, clicked, opened, closed;
  final void Function(double valueMicros, String currency, String precision)
  paid;
}

abstract interface class BannerHandle {
  BannerSize get size;
  Future<void> load();
  Widget buildView();
  Future<void> dispose();
}

/// Implemented alongside AdsBackend, but not a fullscreen cache format.
abstract interface class BannerBackend {
  Future<BannerHandle?> createBanner({
    required int width,
    required BannerCallbacks callbacks,
  });
}
