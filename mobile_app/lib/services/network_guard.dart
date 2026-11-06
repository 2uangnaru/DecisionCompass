import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../widgets/celestial_network_dialog.dart';

/// Whether the device can reach the internet right now.
typedef InternetCheck = Future<bool> Function();

/// Hosts tried at once; any one answering is enough. Baidu is there because
/// Google is unreachable from mainland China, where the app ships in Chinese.
const _probeHosts = ['www.google.com', 'www.baidu.com', 'www.apple.com'];

/// A TCP handshake on 443, not a DNS lookup: Android can answer a lookup from
/// its cache while offline. Nothing is sent once connected.
Future<bool> probeInternet({
  Duration timeout = const Duration(seconds: 5),
}) async {
  final result = Completer<bool>();
  var pending = _probeHosts.length;
  for (final host in _probeHosts) {
    Socket.connect(host, 443, timeout: timeout).then(
      (socket) {
        socket.destroy();
        if (!result.isCompleted) result.complete(true);
      },
      onError: (Object _) {
        if (--pending == 0 && !result.isCompleted) result.complete(false);
      },
    );
  }
  return result.future.timeout(
    timeout + const Duration(seconds: 1),
    onTimeout: () => false,
  );
}

/// Shows the blocking network dialog while the app is offline.
///
/// At startup [ensureOnline] holds the startup screen until a check succeeds,
/// so the reader's day is never shown first. After that it checks on every
/// resume and every [pollEvery] in the foreground. One failed probe can be a
/// blip on a slow network, so a second has to fail before the dialog appears.
/// The dialog closes itself only once a check succeeds.
class NetworkGuard {
  NetworkGuard({
    required this.navigatorKey,
    required this.check,
    this.pollEvery = const Duration(seconds: 15),
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final InternetCheck check;
  final Duration pollEvery;

  Timer? _poll;
  bool _busy = false, _started = false, _foreground = true, _disposed = false;

  /// Resolves once online. [first] is a probe already started, so the check
  /// runs alongside the startup animation rather than after it.
  Future<void> ensureOnline({Future<bool>? first}) async {
    _busy = true;
    try {
      await _guard(first: first);
    } finally {
      _busy = false;
    }
  }

  /// Background checks, once the content is on screen.
  void start() {
    _started = true;
    _schedule();
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!_started) return;
    if (foreground) {
      _schedule();
      unawaited(checkNow());
    } else {
      _poll?.cancel();
    }
  }

  void _schedule() {
    _poll?.cancel();
    if (!_disposed) _poll = Timer.periodic(pollEvery, (_) => checkNow());
  }

  /// Covers both the probe and the dialog's whole life, so neither stacks.
  Future<void> checkNow() async {
    if (_busy || !_foreground || _disposed) return;
    _busy = true;
    try {
      await _guard();
    } finally {
      _busy = false;
    }
  }

  Future<void> _guard({Future<bool>? first}) async {
    final online = await (first ?? check()) || await check();
    if (online || !_foreground || _disposed) return;
    final navigator = navigatorKey.currentState;
    if (navigator == null) await WidgetsBinding.instance.endOfFrame;
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null || !context.mounted || _disposed) return;
    await showCelestialNetworkDialog(context, isOnline: check);
  }

  void dispose() {
    _disposed = true;
    _poll?.cancel();
  }
}
