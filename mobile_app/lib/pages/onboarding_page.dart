import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

import '../app_profile.dart';
import '../local_engine/time/tzdb.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
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
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  void _pickBirthCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      showSearch: true,
      searchAutofocus: true,
      // The picker includes a few territories absent from the bundled time
      // database. Offer only codes the calculation engine can resolve.
      countryFilter: tzdbCountries(),
      countryListTheme: const CountryListThemeData(
        backgroundColor: CompassColors.raised,
        textStyle: TextStyle(color: CompassColors.text),
        inputDecoration: InputDecoration(
          labelText: 'Search countries',
          prefixIcon: Icon(Icons.search_rounded),
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

  String get _birthTimeValue =>
      '${_birthTime.hour.toString().padLeft(2, '0')}:'
      '${_birthTime.minute.toString().padLeft(2, '0')}';

  void _continueToProfile() => setState(() => _step = 1);

  Future<void> _finish() async {
    final birthDate = _birthDate;
    final birthCountry = _birthCountry;
    if (birthDate == null || birthCountry == null) {
      setState(() => _showRequiredErrors = true);
      return;
    }
    final name = _nameController.text.trim().isEmpty
        ? 'Explorer'
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ASTRACUE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: CompassColors.gold,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      OrbitVisual(
                        size: compact ? 170 : 230,
                        labels: const [
                          'MOMENT',
                          'RHYTHM',
                          'BALANCE',
                          'ALMANAC',
                        ],
                      ),
                      SizedBox(height: compact ? 14 : 28),
                      Text(
                        'Read the moment\nwhere you are.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Readings use your device time zone for today’s timing. No location permission is needed.',
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
                        label: const Text('Continue'),
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
              ),
              const Spacer(),
              Text(
                'YOUR PROFILE',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: CompassColors.gold, letterSpacing: 1.8),
              ),
              const Spacer(),
              const SizedBox(width: 48),
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
                  ? 'YOUR SIGN APPEARS AFTER YOUR BIRTH DATE'
                  : zodiacForDate(_birthDate!).label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: CompassColors.gold, letterSpacing: 1.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Build your personal pattern.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'These details shape the cycles used in every reading.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 26),
          TextField(
            key: const Key('name_field'),
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Name'),
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
                        'Date of birth',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _birthDate == null
                            ? 'Select your date of birth'
                            : '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}',
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
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 12),
              child: Text(
                'Select your birth date to continue.',
                style: TextStyle(color: CompassColors.coral),
              ),
            ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: SwitchListTile.adaptive(
              key: const Key('birth_time_unknown'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Birth time unknown'),
              subtitle: const Text(
                'We will compare possible birth-hour patterns.',
              ),
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
                          'Time of birth',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _birthTimeValue,
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
                        'Country of birth',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _birthCountry?.name ?? 'Search and select a country',
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
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 12),
              child: Text(
                'Select your country of birth to continue.',
                style: TextStyle(color: CompassColors.coral),
              ),
            ),
          const SizedBox(height: 28),
          FilledButton(
            key: const Key('complete_profile'),
            onPressed: _finish,
            child: const Text('Create My Compass'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Your birth details remain private in this prototype.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: CompassColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
