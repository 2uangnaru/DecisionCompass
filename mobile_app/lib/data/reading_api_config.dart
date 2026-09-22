import 'reading_api_exception.dart';

/// Validated base URL for the calculation API.
///
/// There is no default and no bundled production URL: the value must be
/// supplied at build time, so a build can never silently point at someone
/// else's server.
///
/// ```sh
/// flutter run --dart-define=DECISION_API_BASE_URL=http://127.0.0.1:8787
/// ```
///
/// Local development targets (the Node server stays bound to loopback — never
/// rebind it to 0.0.0.0 to reach a device):
///
/// | Target | Base URL |
/// |---|---|
/// | Android emulator | `http://10.0.2.2:8787` |
/// | iOS simulator, Flutter desktop | `http://127.0.0.1:8787` |
/// | Physical Android + `adb reverse tcp:8787 tcp:8787` | `http://127.0.0.1:8787` |
class ReadingApiConfig {
  ReadingApiConfig._(this.baseUrl);

  /// Normalized base URL, always without a trailing slash.
  final Uri baseUrl;

  /// The compile-time value of `DECISION_API_BASE_URL`, empty when unset.
  static const String defineKey = 'DECISION_API_BASE_URL';
  static const String _rawFromEnvironment = String.fromEnvironment(defineKey);

  /// Reads the base URL from `--dart-define=DECISION_API_BASE_URL=...`.
  ///
  /// Throws [ReadingApiException] with
  /// [ReadingApiFailureKind.configuration] when the define is missing or
  /// unusable, rather than falling back to a guessed host.
  factory ReadingApiConfig.fromEnvironment() =>
      ReadingApiConfig.parse(_rawFromEnvironment);

  /// Validates an explicit base URL. Used by tests and by
  /// [ReadingApiConfig.fromEnvironment].
  factory ReadingApiConfig.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw _configError(
        'missing_api_base_url',
        'No API base URL was provided. Pass '
            '--dart-define=$defineKey=http://127.0.0.1:8787 when building.',
      );
    }

    final parsed = Uri.tryParse(trimmed);
    // Checked via `scheme`, not `isAbsolute`: Dart treats any URI carrying a
    // fragment as non-absolute, which would mask the fragment check below
    // behind a vaguer "malformed" verdict.
    if (parsed == null || parsed.scheme.isEmpty) {
      throw _configError(
        'malformed_api_base_url',
        'The API base URL is not a valid absolute URL.',
      );
    }
    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      // Never upgrade http to https implicitly: a silent scheme change would
      // hide a misconfigured build instead of failing it.
      throw _configError(
        'unsupported_api_scheme',
        'The API base URL must use http or https.',
      );
    }
    if (parsed.host.isEmpty) {
      throw _configError(
        'malformed_api_base_url',
        'The API base URL has no host.',
      );
    }
    if (parsed.userInfo.isNotEmpty) {
      throw _configError(
        'credentials_in_api_base_url',
        'The API base URL must not embed credentials.',
      );
    }
    if (parsed.hasQuery) {
      throw _configError(
        'query_in_api_base_url',
        'The API base URL must not contain a query string.',
      );
    }
    if (parsed.hasFragment) {
      throw _configError(
        'fragment_in_api_base_url',
        'The API base URL must not contain a fragment.',
      );
    }

    // Strip trailing slashes so joining a path cannot produce "//v1/readings",
    // while keeping an explicitly supplied port intact.
    var path = parsed.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return ReadingApiConfig._(parsed.replace(path: path));
  }

  /// Absolute URL of the readings endpoint, preserving any base path and port.
  Uri get readingsEndpoint =>
      baseUrl.replace(path: '${baseUrl.path}/v1/readings');

  /// True when traffic is unencrypted. Acceptable on loopback during local
  /// development; production builds must use https.
  bool get isCleartext => baseUrl.scheme == 'http';

  @override
  String toString() => 'ReadingApiConfig($baseUrl)';
}

ReadingApiException _configError(String code, String message) =>
    ReadingApiException(
      kind: ReadingApiFailureKind.configuration,
      safeCode: code,
      safeMessage: message,
    );
