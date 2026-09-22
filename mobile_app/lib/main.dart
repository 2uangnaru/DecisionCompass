import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'data/current_context_provider.dart';
import 'data/http_reading_repository.dart';
import 'data/misconfigured_reading_repository.dart';
import 'data/reading_api_config.dart';
import 'data/reading_api_exception.dart';
import 'data/reading_repository.dart';
import 'reading_dependencies.dart';

void main() {
  // This client is owned here, for the whole app lifetime, and closed on
  // detach. HttpReadingRepository never closes a client it was given.
  final client = http.Client();

  runApp(
    DecisionCompassApp(
      dependencies: ReadingDependencies(
        repository: _buildRepository(client),
        contextProvider: const DeviceCurrentContextProvider(),
      ),
      onDetached: client.close,
    ),
  );
}

/// A missing or malformed `DECISION_API_BASE_URL` must not crash the launch or
/// silently fall back to a guessed host. The app starts and the configuration
/// failure appears in the reading flow's error state instead.
ReadingRepository _buildRepository(http.Client client) {
  try {
    return HttpReadingRepository(
      client: client,
      config: ReadingApiConfig.fromEnvironment(),
    );
  } on ReadingApiException catch (failure) {
    return MisconfiguredReadingRepository(failure);
  }
}
