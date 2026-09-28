import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

import '../app_profile.dart';
import '../l10n/app_localizations.dart';
import '../local_engine/time/tzdb.dart';
import '../localized_presentation.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import '../widgets/language_selector.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.dependencies,
    this.initialSafetyAcknowledged = false,
  });

  final ReadingDependencies dependencies;
  final bool initialSafetyAcknowledged;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController = TextEditingController();
  var _step = 0;
  DateTime? _birthDate;
  var _birthTimeUnknown = true;
  var _birthTime = const TimeOfDay(hour: 14, minute: 30);
  Country? _birthCountry;
  var _showRequiredErrors = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      // Flutter's own typed-entry field dismisses the keyboard the instant
      // it's cleared to empty (a framework quirk, not something this app
      // controls), so the dialog opens on the calendar/year-grid by default.
      // Its own keyboard icon still switches to typed entry for anyone who
      // wants to type the date instead.
      //
      // The dialog's own chrome follows the app locale through
      // `GlobalMaterialLocalizations`, so month names, weekday initials and
      // the entry format are the reader's, not English.
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  void _pickBirthCountry() {
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
      onSelect: (country) => setState(() => _birthCountry = country),
    );
  }

  Future<void> _pickBirthTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime,
    );
    if (picked != null && mounted) setState(() => _birthTime = picked);
  }

  /// The engine's `HH:mm`, always 24-hour and never localized: it is a wire
  /// value, not something the reader reads.
  String get _birthTimeValue =>
      '${_birthTime.hour.toString().padLeft(2, '0')}:'
      '${_birthTime.minute.toString().padLeft(2, '0')}';

  /// What the reader sees instead, in their own clock convention.
  String _birthTimeDisplay(String localeName) =>
      formatClock(localeName, _birthTime.hour, _birthTime.minute);

  void _continueToProfile() => setState(() => _step = 1);

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final birthDate = _birthDate;
    final birthCountry = _birthCountry;
    if (birthDate == null || birthCountry == null) {
      setState(() => _showRequiredErrors = true);
      return;
    }
    final name = _nameController.text.trim().isEmpty
        ? l10n.defaultUserName
        : _nameController.text.trim();
    final profile = AppProfile(
      userName: name,
      birthDate: birthDate,
      birthTime: _birthTimeUnknown ? null : _birthTimeValue,
      birthCountryCode: birthCountry.countryCode,
      zodiacSign: zodiacForDate(birthDate),
      useCurrentLocation: false,
      safetyAcknowledged: widget.initialSafetyAcknowledged,
    );
    await widget.dependencies.profileRepository.save(profile);
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
                      Text(
                        'ASTRACUE',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: CompassColors.gold,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const Spacer(),
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
                        l10n.onboardingTitle,
                        key: const Key('onboarding_title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.onboardingLanguageHint,
                        key: const Key('onboarding_language_hint'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Column(
                    children: [
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
    return SingleChildScrollView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _step = 0),
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
                : ZodiacAvatar(
                    size: 92,
                    glow: true,
                    sign: zodiacForDate(_birthDate!),
                  ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _birthDate == null
                  ? l10n.signAfterBirthDate
                  : zodiacLabel(l10n, zodiacForDate(_birthDate!)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: CompassColors.gold, letterSpacing: 1.7),
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
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.nameField),
          ),
          const SizedBox(height: 14),
          GlassCard(
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
            child: SwitchListTile.adaptive(
              key: const Key('birth_time_unknown'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.birthTimeUnknown),
              subtitle: Text(l10n.birthTimeUnknownDetail),
              value: _birthTimeUnknown,
              onChanged: (value) => setState(() => _birthTimeUnknown = value),
            ),
          ),
          if (!_birthTimeUnknown) ...[
            const SizedBox(height: 14),
            GlassCard(
              key: const Key('birth_time_picker'),
              onTap: _pickBirthTime,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: CompassColors.gold),
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
                          _birthTimeDisplay(localeName),
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
          FilledButton(
            key: const Key('complete_profile'),
            onPressed: _finish,
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
    );
  }
}
