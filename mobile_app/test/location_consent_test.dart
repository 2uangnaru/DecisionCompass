import 'package:decision_compass/data/current_context_provider.dart';
import 'package:decision_compass/data/location_gateway.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/data/reading_api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// Records every call so a test can prove the plugin seam was never touched.
/// Mimics a device where permission was granted in an earlier session.
class RecordingLocationGateway implements LocationGateway {
  RecordingLocationGateway({
    this.permitted = true,
    this.serviceEnabled = true,
    this.fix,
  });

  final bool permitted;
  final bool serviceEnabled;
  final LocationFix? fix;

  final List<String> calls = [];

  @override
  Future<void> requestPermission() async => calls.add('requestPermission');

  @override
  Future<bool> hasPermission() async {
    calls.add('hasPermission');
    return permitted;
  }

  @override
  Future<bool> isServiceEnabled() async {
    calls.add('isServiceEnabled');
    return serviceEnabled;
  }

  @override
  Future<LocationFix?> currentFix(Duration timeout) async {
    calls.add('currentFix');
    return fix;
  }
}

final _instant = DateTime.utc(2026, 9, 18, 8, 30);

LocationFix freshFix({DateTime? at}) => LocationFix(
  latitude: 10.7769,
  longitude: 106.7009,
  accuracyMeters: 42,
  timestampUtc: at ?? _instant,
);

void main() {
  group('DeviceCurrentContextProvider location gating', () {
    test('opting out never touches the location plugin at all', () async {
      // Permission is granted and a valid fix is waiting: exactly the
      // earlier-session case that used to leak coordinates.
      final gateway = RecordingLocationGateway(fix: freshFix());
      final provider = DeviceCurrentContextProvider(gateway: gateway);

      final context = await provider.capture(
        instantUtc: _instant,
        includeLocation: false,
      );

      expect(context.location, isNull);
      expect(
        gateway.calls,
        isEmpty,
        reason: 'no permission, service or position call may happen',
      );
      // The timezone is still resolved (UTC here, since the timezone plugin is
      // unavailable in tests and the provider falls back rather than failing).
      expect(
        context.deviceTimezone,
        DeviceCurrentContextProvider.fallbackTimezone,
      );
      expect(context.instantUtc, _instant.toIso8601String());
    });

    test(
      'opting in uses the permission, service and position checks',
      () async {
        final gateway = RecordingLocationGateway(fix: freshFix());
        final provider = DeviceCurrentContextProvider(gateway: gateway);

        final context = await provider.capture(
          instantUtc: _instant,
          includeLocation: true,
        );

        expect(gateway.calls, [
          'hasPermission',
          'isServiceEnabled',
          'currentFix',
        ]);
        expect(context.location, isNotNull);
        expect(context.location!.latitude, 10.7769);
        expect(context.location!.longitude, 106.7009);
        expect(context.location!.accuracyMeters, 42);
        expect(context.location!.capturedAtUtc, _instant.toIso8601String());
      },
    );

    test('a denied permission stops before the position call', () async {
      final gateway = RecordingLocationGateway(
        permitted: false,
        fix: freshFix(),
      );
      final provider = DeviceCurrentContextProvider(gateway: gateway);

      final context = await provider.capture(
        instantUtc: _instant,
        includeLocation: true,
      );

      expect(gateway.calls, ['hasPermission']);
      expect(context.location, isNull);
      expect(context.deviceTimezone, isNotEmpty);
    });

    test('a disabled location service degrades to no location', () async {
      final gateway = RecordingLocationGateway(
        serviceEnabled: false,
        fix: freshFix(),
      );
      final provider = DeviceCurrentContextProvider(gateway: gateway);

      final context = await provider.capture(
        instantUtc: _instant,
        includeLocation: true,
      );

      expect(gateway.calls, ['hasPermission', 'isServiceEnabled']);
      expect(context.location, isNull);
    });

    test('a stale fix is dropped rather than sent', () async {
      final gateway = RecordingLocationGateway(
        fix: freshFix(at: _instant.subtract(const Duration(minutes: 16))),
      );
      final provider = DeviceCurrentContextProvider(gateway: gateway);

      final context = await provider.capture(
        instantUtc: _instant,
        includeLocation: true,
      );

      expect(context.location, isNull);
    });

    test('a thrown plugin error never blocks the reading', () async {
      final provider = DeviceCurrentContextProvider(
        gateway: _ThrowingGateway(),
      );

      final context = await provider.capture(
        instantUtc: _instant,
        includeLocation: true,
      );

      expect(context.location, isNull);
      expect(context.deviceTimezone, isNotEmpty);
      expect(context.instantUtc, _instant.toIso8601String());
    });

    test('requestLocationAccess swallows a refused permission flow', () async {
      final provider = DeviceCurrentContextProvider(
        gateway: _ThrowingGateway(),
      );
      await expectLater(provider.requestLocationAccess(), completes);
    });
  });

  group('the explainer choice reaches the request', () {
    testWidgets('"Use Device Time Zone Instead" asks for no permission', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        location: const CurrentLocation(
          latitude: 10.7769,
          longitude: 106.7009,
          accuracyMeters: 42,
          capturedAtUtc: '2026-09-18T08:29:45.000Z',
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester, allowLocation: false);
      await revealReading(tester);
      await tester.pump();

      expect(rig.contextProvider.locationAccessRequests, 0);
      expect(rig.contextProvider.captures.single.includeLocation, isFalse);
      // Even though the rig has a location available.
      expect(rig.sentRequest!.context.location, isNull);
      expect(rig.sentRequest!.context.deviceTimezone, 'Asia/Ho_Chi_Minh');

      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();
    });

    testWidgets('"Allow Current Location" requests permission exactly once', (
      tester,
    ) async {
      const fix = CurrentLocation(
        latitude: 10.7769,
        longitude: 106.7009,
        accuracyMeters: 42,
        capturedAtUtc: '2026-09-18T08:29:45.000Z',
      );
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        location: fix,
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await tester.pump();

      expect(rig.contextProvider.locationAccessRequests, 1);
      expect(rig.contextProvider.captures.single.includeLocation, isTrue);
      final sent = rig.sentRequest!.context.location!;
      expect(sent.latitude, fix.latitude);
      expect(sent.longitude, fix.longitude);
      expect(sent.accuracyMeters, fix.accuracyMeters);
      expect(sent.capturedAtUtc, fix.capturedAtUtc);

      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();
    });

    testWidgets('going back and choosing device timezone wins', (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        location: const CurrentLocation(
          latitude: 10.7769,
          longitude: 106.7009,
          accuracyMeters: 42,
          capturedAtUtc: '2026-09-18T08:29:45.000Z',
        ),
      );
      await tester.pumpWidget(rig.app);
      await tester.pump(); // let the startup profile-load future settle

      // Opt in first...
      await tester.tap(find.byKey(const Key('allow_location')));
      await tester.pumpAndSettle();
      expect(rig.contextProvider.locationAccessRequests, 1);

      // ...then go back and change the answer. The explainer's orbit animates
      // forever, so this steps the clock instead of settling.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('skip_location')), findsOneWidget);

      await tester.tap(find.byKey(const Key('skip_location')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.ensureVisible(find.byKey(const Key('complete_profile')));
      await tester.tap(find.byKey(const Key('complete_profile')));
      await tester.pumpAndSettle();
      await revealReading(tester);
      await tester.pump();

      expect(rig.contextProvider.captures.single.includeLocation, isFalse);
      expect(rig.sentRequest!.context.location, isNull);
      // No second permission prompt came from opting out.
      expect(rig.contextProvider.locationAccessRequests, 1);

      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();
    });

    testWidgets('a retry reuses the request and captures location once', (
      tester,
    ) async {
      final rig = ReadingTestRig(
        error: const ReadingApiException(
          kind: ReadingApiFailureKind.network,
          safeCode: 'reading_service_unreachable',
          safeMessage: 'The reading service could not be reached.',
        ),
        location: const CurrentLocation(
          latitude: 10.7769,
          longitude: 106.7009,
          accuracyMeters: 42,
          capturedAtUtc: '2026-09-18T08:29:45.000Z',
        ),
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await revealReading(tester);
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('retry_reading')), findsOneWidget);
      rig.repository
        ..error = null
        ..respondWith(fixtureResponse('ready_yes_no_now.json'));

      await tester.tap(find.byKey(const Key('retry_reading')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();

      expect(find.text('YOUR DIRECTION'), findsOneWidget);
      expect(rig.repository.requests, hasLength(2));
      // One capture only: the retry reused the original request.
      expect(rig.contextProvider.captures, hasLength(1));
      expect(
        rig.repository.requests.first.context.location!.capturedAtUtc,
        rig.repository.requests.last.context.location!.capturedAtUtc,
      );
    });
  });
}

class _ThrowingGateway implements LocationGateway {
  @override
  Future<void> requestPermission() async => throw Exception('plugin missing');

  @override
  Future<bool> hasPermission() async => throw Exception('plugin missing');

  @override
  Future<bool> isServiceEnabled() async => throw Exception('plugin missing');

  @override
  Future<LocationFix?> currentFix(Duration timeout) async =>
      throw Exception('plugin missing');
}
