import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart' hide showCountryPicker;

import '../widgets/compass_country_picker.dart';

import '../app_profile.dart';
import '../analytics/analytics_event.dart';
import '../l10n/app_localizations.dart';
import '../local_engine/time/tzdb.dart';
import '../localized_presentation.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../widgets/birth_date_picker.dart';
import '../widgets/birth_time_picker.dart';
import '../widgets/celestial_ui.dart';
import '../widgets/language_selector.dart';
import '../widgets/analytics_consent_tile.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.dependencies,
    this.initialSafetyAcknowledged = false,
    this.initialProfile,
  });

  final ReadingDependencies dependencies;
  final bool initialSafetyAcknowledged;

  /// The profile being edited, or null when creating one.
  ///
  /// An existing profile keeps the answers it was saved with — in particular
  /// whether its birth time was known. Re-opening it must not quietly flip an
  /// "I do not know my birth time" back to "I do", which would either block
  /// the reader or invite them to invent an hour.
  ///
  /// Nothing routes here yet: there is no profile-editing screen in this
  /// build. The parameter exists so the behaviour is defined and tested for
  /// whichever screen adds one.
  final AppProfile? initialProfile;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final _nameController = TextEditingController(
    text: widget.initialProfile?.userName ?? '',
  );
  final _nameFocusNode = FocusNode();
  var _step = 0;
  late DateTime? _birthDate = widget.initialProfile?.birthDate;

  /// On for a new profile: most readers do know their birth time, and the
  /// hour is what the earthly-branch cycles are built from, so the default
  /// invites them to give it. An existing profile keeps whatever it was
  /// saved with.
  late bool _knowsBirthTime =
      widget.initialProfile == null || widget.initialProfile!.birthTime != null;

  /// Null until the reader picks one. Never seeded with noon, midnight, the
  /// current time or any other invented hour: a fabricated birth time is
  /// indistinguishable from a real one once it reaches the engine, and it
  /// would silently produce a confident reading from a guess.
  late TimeOfDay? _birthTime = _parseBirthTime(
    widget.initialProfile?.birthTime,
  );

  Country? _birthCountry;
  var _showRequiredErrors = false;

  /// True while the profile is being written.
  ///
  /// Creating a compass is one button and one outcome. Without this, a double
  /// tap writes the profile twice and runs the country-language rule twice,
  /// and the second run would find the provenance the first one set and read
  /// as "somebody already chose".
  var _finishing = false;

  /// Set when writing the profile failed. The reader stays on this screen with
  /// the form intact, and nothing about their language is touched.
  var _profileSaveFailed = false;

  /// Set when the reader closed the time dialog without answering it, as well
  /// as when they try to continue. Separate from [_showRequiredErrors] so
  /// dismissing the dialog does not also light up the date and country.
  var _showBirthTimeError = false;
  bool _onboardingTracked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _trackOnboarding();
    });
  }

  void _trackOnboarding() {
    if (_onboardingTracked || widget.initialProfile != null) return;
    _onboardingTracked = widget.dependencies.analytics.record(
      AnalyticsEvent.onboardingStarted(),
    );
  }

  /// Reads the stored `HH:mm` back. A record that cannot be parsed is treated
  /// as no time at all rather than repaired into one.
  static TimeOfDay? _parseBirthTime(String? stored) {
    if (stored == null) return null;
    final parts = stored.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _unfocus() {
    _nameFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    _unfocus();
    final picked = await showBirthDatePicker(
      context: context,
      initialDate: _birthDate,
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  void _pickBirthCountry() {
    _unfocus();
    final l10n = AppLocalizations.of(context);
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      showSearch: true,
      searchAutofocus: true,
      // The picker includes a few territories absent from the bundled time
      // database. Offer only codes the calculation engine can resolve.
      countryFilter: tzdbCountries(),
      countryListTheme: CountryListThemeData(
        backgroundColor: CompassColors.raised,
        textStyle: const TextStyle(color: CompassColors.text),
        inputDecoration: InputDecoration(
          labelText: l10n.searchCountries,
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
      onSelect: (country) {
        _unfocus();
        setState(() => _birthCountry = country);
      },
    );
  }

  Future<void> _pickBirthTime() async {
    _unfocus();
    final l10n = AppLocalizations.of(context);
    // A twelve-hour dial with an AM/PM selector, whose selection starts empty
    // — see `showBirthTimePicker`. Null means the reader gave no answer:
    // cancelled, or closed it without completing a choice. The field stays
    // unanswered rather than taking an hour nobody picked.
    final picked = await showBirthTimePicker(
      context: context,
      helpText: l10n.selectBirthTime,
      current: _birthTime,
    );
    if (!mounted) return;
    setState(() {
      if (picked != null) {
        _birthTime = picked;
      } else if (_birthTime == null) {
        // Say why nothing happened, rather than leaving the reader to press
        // Continue to find out.
        _showBirthTimeError = true;
      }
    });
  }

  /// Turning the control off stores "unknown"; turning it back on asks again.
  ///
  /// The previously chosen time is dropped rather than held aside, so a
  /// reader who says they do not know their birth time and then changes their
  /// mind cannot have an earlier answer restored on their behalf.
  void _setKnowsBirthTime(bool value) {
    _unfocus();
    setState(() {
      _knowsBirthTime = value;
      _birthTime = null;
      _showRequiredErrors = false;
      _showBirthTimeError = false;
    });
  }

  /// The engine's `HH:mm`, always 24-hour and never localized: it is a wire
  /// value, not something the reader reads.
  ///
  /// Null whenever the birth time is unknown, which is what puts the reading
  /// on the engine's unknown-birth-hour path.
  String? get _birthTimeValue {
    final time = _knowsBirthTime ? _birthTime : null;
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// What the reader sees instead, in their own clock convention.
  String? _birthTimeDisplay(String localeName) {
    final time = _birthTime;
    if (time == null) return null;
    return formatClock(localeName, time.hour, time.minute);
  }

  /// The control is on, but no time has been chosen yet.
  bool get _birthTimeMissing => _knowsBirthTime && _birthTime == null;

  void _continueToProfile() => setState(() => _step = 1);

  Future<void> _finish() async {
    _unfocus();
    // A second tap while the first is in flight does nothing at all.
    if (_finishing) return;
    final birthDate = _birthDate;
    final birthCountry = _birthCountry;
    // Continuing with the control on but no time chosen is what the
    // validation message is for: it must not fall through to a default hour.
    //
    // An incomplete form returns here, before anything is saved and before
    // the language rule is consulted: a form that was not accepted must not
    // change the app's language as a side effect.
    if (birthDate == null || birthCountry == null || _birthTimeMissing) {
      setState(() {
        _showRequiredErrors = true;
        _showBirthTimeError = true;
      });
      return;
    }
    final typed = _nameController.text.trim();
    final profile = AppProfile(
      // Null, not the word: the greeting picks the default up in whatever
      // language is active when it is shown.
      userName: typed.isEmpty ? null : typed,
      birthDate: birthDate,
      birthTime: _birthTimeValue,
      birthCountryCode: birthCountry.countryCode,
      zodiacSign: zodiacForDate(birthDate),
      useCurrentLocation: false,
      safetyAcknowledged: widget.initialSafetyAcknowledged,
      createdAt: widget.dependencies.nowLocal(),
    );
    setState(() {
      _finishing = true;
      _profileSaveFailed = false;
    });
    try {
      await widget.dependencies.profileRepository.save(profile);
      if (widget.initialProfile == null) {
        widget.dependencies.analytics.record(
          AnalyticsEvent.onboardingCompleted(),
        );
      }
    } catch (_) {
      // The profile is not saved, so nothing has happened yet — including to
      // the language. The reader keeps their form and can try again.
      if (!mounted) return;
      setState(() {
        _finishing = false;
        _profileSaveFailed = true;
      });
      return;
    }
    if (!mounted) return;

    // Held across the navigation: `ScaffoldMessenger` lives above the
    // navigator, so a notice shown through it survives onto Home, but this
    // page's own context does not.
    // Applied before Home is pushed. The controller notifies synchronously,
    // so the app is already rebuilding in the new language by the time Home
    // is constructed — it is never built in English and then swapped.
    //
    // The result is deliberately unused. The switch is silent: a notice used
    // to name the new language and offer the selector, and it was dropped on
    // request. The trade is real and worth knowing — a reader whose app comes
    // up in a language they did not pick is given no reason for it and is not
    // pointed at the globe that undoes it — so if that turns out to be the
    // wrong call, `git log` has the notice intact.
    await widget.dependencies.localeController.applyBirthCountryDefault(
      profile.birthCountryCode,
    );
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            HomePage(profile: profile, dependencies: widget.dependencies),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CelestialScaffold(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: _step == 0 ? _locationStep() : _profileStep(),
      ),
    );
  }

  Widget _locationStep() {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      key: const ValueKey('location'),
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                compact ? 18 : 32,
                24,
                compact ? 14 : 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ASTRACUE',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: CompassColors.gold,
                                    letterSpacing: 2.8,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // On the welcome screen itself, above the profile step:
                      // an obvious globe and the current language, never an
                      // unsolicited popup and never an extra required screen.
                      LanguageButton(
                        controller: widget.dependencies.localeController,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      OrbitVisual(
                        size: compact ? 170 : 230,
                        labels: welcomeOrbitLabels(l10n),
                      ),
                      SizedBox(height: compact ? 14 : 28),
                      Text(
                        l10n.onboardingLanguageHint,
                        key: const Key('onboarding_language_hint'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.onboardingTitle,
                        key: const Key('onboarding_title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: CompassColors.muted,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      AnalyticsConsentTile(
                        analytics: widget.dependencies.analytics,
                        onEnabled: _trackOnboarding,
                      ),
                      FilledButton.icon(
                        key: const Key('continue_to_profile'),
                        onPressed: _continueToProfile,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.continueAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _profileStep() {
    final l10n = AppLocalizations.of(context);
    final localeName = intlLocaleOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _unfocus,
      child: SingleChildScrollView(
        key: const ValueKey('profile'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    _unfocus();
                    setState(() => _step = 0);
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: l10n.backAction,
                ),
                // Expanded rather than a pair of Spacers: the eyebrow is a
                // single word in English and four in Japanese, and at a large
                // text scale the fixed-width version pushed the language
                // control off the right edge.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.yourProfile,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: CompassColors.gold,
                        letterSpacing: trackingFor(context, 1.8),
                      ),
                    ),
                  ),
                ),
                // Still reachable while entering a profile: a reader who only
                // now realises the app speaks their language should not have to
                // back out to change it.
                LanguageButton(
                  controller: widget.dependencies.localeController,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: _birthDate == null
                  ? const Icon(
                      Icons.auto_awesome_rounded,
                      size: 72,
                      color: CompassColors.gold,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ZodiacAvatar(
                          size: 92,
                          glow: true,
                          sign: zodiacForDate(_birthDate!),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          zodiacLabel(l10n, zodiacForDate(_birthDate!)),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: CompassColors.gold,
                                letterSpacing: 1.7,
                              ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.buildPattern,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.profileExplainer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 26),
            TextField(
              key: const Key('name_field'),
              controller: _nameController,
              focusNode: _nameFocusNode,
              onTapOutside: (_) => _unfocus(),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.nameField),
            ),
            const SizedBox(height: 14),
            GlassCard(
              key: const Key('birth_date_picker'),
              onTap: _pickBirthDate,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: CompassColors.gold,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dateOfBirth,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _birthDate == null
                              ? l10n.selectBirthDate
                              : formatDate(localeName, _birthDate!),
                          key: const Key('birth_date_value'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            if (_showRequiredErrors && _birthDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  l10n.birthDateRequired,
                  style: const TextStyle(color: CompassColors.coral),
                ),
              ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              // Stated the way the reader would state it, and on by default.
              // The old switch said "Birth time unknown", which made the
              // affirmative answer the one you had to turn *off* — easy to
              // misread, and it defaulted every new profile to unknown.
              child: SwitchListTile.adaptive(
                key: const Key('knows_birth_time'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.knowBirthTime),
                subtitle: Text(
                  _knowsBirthTime
                      ? l10n.knowBirthTimeDetail
                      : l10n.birthTimeUnknownDetail,
                ),
                value: _knowsBirthTime,
                onChanged: _setKnowsBirthTime,
              ),
            ),
            if (_knowsBirthTime) ...[
              const SizedBox(height: 14),
              GlassCard(
                key: const Key('birth_time_picker'),
                onTap: _pickBirthTime,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: CompassColors.gold,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.timeOfBirth,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            // A prompt until the reader answers it — never a
                            // plausible-looking hour they did not choose.
                            _birthTimeDisplay(localeName) ??
                                l10n.selectBirthTime,
                            key: const Key('birth_time_value'),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              if (_showBirthTimeError && _birthTimeMissing)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    l10n.birthTimeRequired,
                    key: const Key('birth_time_required'),
                    style: const TextStyle(color: CompassColors.coral),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            GlassCard(
              key: const Key('birth_country'),
              onTap: _pickBirthCountry,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.public_rounded, color: CompassColors.gold),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.countryOfBirth,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          // The picker's own localized name where it has one,
                          // which is why this reads the country through the
                          // delegate rather than its English `name`.
                          _birthCountry?.getTranslatedName(context) ??
                              _birthCountry?.name ??
                              l10n.selectBirthCountry,
                          key: const Key('birth_country_value'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            if (_showRequiredErrors && _birthCountry == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  l10n.birthCountryRequired,
                  style: const TextStyle(color: CompassColors.coral),
                ),
              ),
            const SizedBox(height: 28),
            if (_profileSaveFailed) ...[
              Text(
                l10n.profileNotSaved,
                key: const Key('profile_save_failed'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 10),
            ],
            FilledButton(
              key: const Key('complete_profile'),
              // Null while a save is in flight: the guard in `_finish` already
              // ignores a second tap, and a dead-looking button says so.
              onPressed: _finishing ? null : _finish,
              child: Text(l10n.createCompass),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.birthPrivacyPrototype,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: CompassColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
