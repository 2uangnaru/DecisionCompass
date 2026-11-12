import 'dart:convert';
import 'dart:io';

/// Validates public build settings. No signing key, password or Apple API key
/// belongs in this file. The native archive/signing still requires macOS.
List<String> validateIOSReleaseConfig(Map<String, Object?> c) {
  final errors = <String>[];
  final monetization = c['IOS_MONETIZATION_ENABLED'] == true;
  if (c.containsKey('IOS_MONETIZATION_ENABLED') &&
      c['IOS_MONETIZATION_ENABLED'] is! bool) {
    errors.add('IOS_MONETIZATION_ENABLED: use a JSON boolean.');
  }
  String text(String key) => c[key] is String ? (c[key]! as String).trim() : '';
  final bundle = text('IOS_BUNDLE_ID');
  if (!RegExp(r'^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+){2,}$').hasMatch(bundle) ||
      bundle.contains('example') ||
      bundle.contains('yourcompany')) {
    errors.add('IOS_BUNDLE_ID: enter your registered, explicit Bundle ID.');
  }
  if (!RegExp(r'^[A-Z0-9]{10}$').hasMatch(text('IOS_DEVELOPMENT_TEAM'))) {
    errors.add('IOS_DEVELOPMENT_TEAM: enter your 10-character Apple Team ID.');
  }
  if (monetization &&
      !RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(text('IOS_PLUS_PRODUCT_ID'))) {
    errors.add(
      'IOS_PLUS_PRODUCT_ID: enter the non-consumable App Store product ID.',
    );
  }
  for (final key in ['PRIVACY_POLICY_URL', 'TERMS_OF_USE_URL', 'SUPPORT_URL']) {
    final uri = Uri.tryParse(text(key));
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.host == 'localhost' ||
        uri.host.endsWith('.invalid') ||
        uri.host.endsWith('.test') ||
        uri.host.contains('example.com')) {
      errors.add('$key: enter a real, public HTTPS page.');
    }
  }
  for (final key in [
    'IOS_ADS_ENABLED',
    'IOS_TRACKING_ENABLED',
    'FIREBASE_ANALYTICS_ENABLED',
    'PLUS_DEMO_BILLING',
  ]) {
    if (c[key] is! bool) errors.add('$key: use a JSON boolean.');
  }
  if (c['PLUS_DEMO_BILLING'] != false) {
    errors.add('PLUS_DEMO_BILLING must be false in a store build.');
  }
  if (!monetization &&
      (c['IOS_ADS_ENABLED'] == true || c['IOS_TRACKING_ENABLED'] == true)) {
    errors.add('Ads/tracking must be disabled while iOS monetization is off.');
  }
  if (c['IOS_TRACKING_ENABLED'] == true && c['IOS_ADS_ENABLED'] != true) {
    errors.add('Do not request tracking when ads are disabled.');
  }
  if (c['IOS_ADS_ENABLED'] == true) {
    if (!RegExp(r'^ca-app-pub-\d{16}~\d{10}$')
            .hasMatch(text('ADMOB_IOS_APP_ID')) ||
        text('ADMOB_IOS_APP_ID').startsWith('ca-app-pub-3940256099942544')) {
      errors.add(
        'ADMOB_IOS_APP_ID: use your live iOS App ID, not a Google sample.',
      );
    }
    for (final key in [
      'ADMOB_IOS_BANNER_UNIT_ID',
      'ADMOB_IOS_INTERSTITIAL_UNIT_ID',
      'ADMOB_IOS_REWARDED_UNIT_ID',
    ]) {
      if (!RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(text(key)) ||
          text(key).startsWith('ca-app-pub-3940256099942544')) {
        errors.add('$key: use a live iOS ad unit ID.');
      }
    }
  }
  // Owner.xcconfig is generated below; never allow another build setting or
  // xcconfig directive to be injected through an identifier or URL.
  for (final e in c.entries) {
    if (e.value is String &&
        (RegExp(r'[\x00-\x20$#"\\]').hasMatch(e.value! as String) ||
            (e.value! as String).contains('/*'))) {
      errors.add('${e.key}: unsupported configuration characters.');
    }
  }
  return errors;
}

String iosOwnerXcconfig(Map<String, Object?> c) {
  String value(String key) => (c[key] as String? ?? '').trim().replaceAll(
    '//',
    r'/$()/',
  ); // xcconfig treats // as a comment.
  return '''// Generated from ios-release.local.json. Public IDs/settings only.
ASTRACUE_BUNDLE_ID = ${value('IOS_BUNDLE_ID')}
ASTRACUE_DEVELOPMENT_TEAM = ${value('IOS_DEVELOPMENT_TEAM')}
ASTRACUE_PLUS_PRODUCT_ID = ${value('IOS_PLUS_PRODUCT_ID')}
${c['IOS_ADS_ENABLED'] == true ? 'ASTRACUE_ADMOB_APP_ID = ${value('ADMOB_IOS_APP_ID')}' : '// Ads disabled: retain the Debug sample or Release empty App ID.'}
ASTRACUE_PRIVACY_POLICY_URL = ${value('PRIVACY_POLICY_URL')}
ASTRACUE_TERMS_URL = ${value('TERMS_OF_USE_URL')}
ASTRACUE_SUPPORT_URL = ${value('SUPPORT_URL')}
''';
}

void main(List<String> args) {
  final configure = args.contains('--configure');
  final files = args.where((a) => !a.startsWith('--')).toList();
  final path = files.isEmpty ? 'ios-release.local.json' : files.single;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln(
      'Copy ios-release.example.json to $path and fill your public settings.',
    );
    exitCode = 1;
    return;
  }
  Map<String, Object?> config;
  try {
    config = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, Object?>();
  } catch (_) {
    stderr.writeln('Invalid release configuration JSON.');
    exitCode = 1;
    return;
  }
  final errors = validateIOSReleaseConfig(config);
  if (config['FIREBASE_ANALYTICS_ENABLED'] == true &&
      !File('ios/Runner/GoogleService-Info.plist').existsSync()) {
    errors.add(
      'Add the genuine iOS GoogleService-Info.plist before enabling Firebase.',
    );
  }
  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  if (configure) {
    File('ios/Flutter/Owner.xcconfig')
        .writeAsStringSync(iosOwnerXcconfig(config));
  }
  stdout.writeln(
    'Configuration is structurally valid. This does not verify ownership, hosting, signing, native SDKs or App Review.',
  );
}
