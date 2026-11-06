import 'package:decision_compass/app.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/widgets/startup_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

/// The offline dialog appears only after two failed probes, cannot be
/// dismissed, and goes away only once a check succeeds. At startup it holds
/// the startup screen: the reader's day is not built until the app is online.
void main() {
  setUpAll(loadBundledFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late bool online;
  late List<bool> results;
  Future<bool> check() async {
    final answer = results.isNotEmpty ? results.removeAt(0) : online;
    return answer;
  }

  final dialog = find.byKey(const Key('network_dialog'));
  final retry = find.byKey(const Key('network_retry'));
  final stillOffline = find.byKey(const Key('network_still_offline'));

  Future<void> start(WidgetTester tester, {required bool startOnline}) async {
    useScreen(tester);
    online = startOnline;
    results = [];
    final rig = ReadingTestRig();
    await rig.profileRepository.save(
      AppProfile(
        userName: 'Alex',
        birthDate: DateTime(2001, 2, 12),
        birthCountryCode: 'VN',
        zodiacSign: ZodiacSign.aquarius,
        useCurrentLocation: false,
        safetyAcknowledged: true,
      ),
    );
    await tester.pumpWidget(
      DecisionCompassApp(dependencies: rig.dependencies, internetCheck: check),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('offline at launch: the dialog covers the startup screen and '
      "the reader's day is not built until online", (tester) async {
    await start(tester, startOnline: false);
    expect(dialog, findsOneWidget);
    expect(find.byType(StartupLoadingView), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(HomePage), findsNothing, reason: 'still held');

    online = true;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(dialog, findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    await finish(tester);
  });

  testWidgets('offline: cannot be dismissed, Reconnect stays until online', (
    tester,
  ) async {
    await start(tester, startOnline: false);
    expect(dialog, findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(dialog, findsOneWidget, reason: 'barrier and Back do nothing');

    await tester.tap(retry);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    expect(dialog, findsOneWidget);
    expect(stillOffline, findsOneWidget);

    online = true;
    await tester.tap(retry);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 400));
    expect(dialog, findsNothing);
    await tester.pump();
    expect(find.byType(HomePage), findsOneWidget);
    await finish(tester);
  });

  testWidgets('closes by itself when the connection comes back', (
    tester,
  ) async {
    await start(tester, startOnline: false);
    expect(dialog, findsOneWidget);
    online = true;
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(dialog, findsNothing);
    expect(stillOffline, findsNothing);
    await finish(tester);
  });

  testWidgets('online at launch: straight to Home, no dialog', (tester) async {
    await start(tester, startOnline: true);
    expect(dialog, findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    await finish(tester);
  });

  testWidgets('one failed probe is a blip, not offline', (tester) async {
    useScreen(tester);
    online = true;
    results = [false];
    await tester.pumpWidget(
      DecisionCompassApp(
        dependencies: ReadingTestRig().dependencies,
        internetCheck: check,
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }
    expect(dialog, findsNothing);
    await finish(tester);
  });

  testWidgets('going offline later is caught by the periodic check, and '
      'again after it closes', (tester) async {
    await start(tester, startOnline: true);
    expect(dialog, findsNothing);

    online = false;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    await tester.pump();
    expect(dialog, findsOneWidget);

    online = true;
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(dialog, findsNothing);

    online = false;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    await tester.pump();
    expect(dialog, findsOneWidget, reason: 'one closed dialog is not the last');
    await finish(tester);
  });

  testWidgets('a resume rechecks at once', (tester) async {
    await start(tester, startOnline: true);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    online = false;
    await tester.pump(const Duration(seconds: 30));
    expect(dialog, findsNothing, reason: 'no checks while in the background');
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(dialog, findsOneWidget);
    await finish(tester);
  });

  testWidgets('no check at all without an internet check (tests, previews)', (
    tester,
  ) async {
    useScreen(tester);
    await tester.pumpWidget(
      DecisionCompassApp(dependencies: ReadingTestRig().dependencies),
    );
    await tester.pump(const Duration(seconds: 20));
    expect(dialog, findsNothing);
    await finish(tester);
  });
}
