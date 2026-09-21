import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController = TextEditingController(text: 'Alex');
  var _step = 0;
  var _birthDate = DateTime(1998, 6, 21);
  var _birthTimeUnknown = true;
  var _country = 'United States';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  void _finish() {
    final name = _nameController.text.trim().isEmpty
        ? 'Explorer'
        : _nameController.text.trim();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            HomePage(userName: name, zodiacSign: zodiacForDate(_birthDate)),
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
                      'DECISION COMPASS',
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
                          'CAN CHI',
                        ],
                        sign: zodiacForDate(_birthDate),
                      ),
                      SizedBox(height: compact ? 14 : 28),
                      Text(
                        'Read the moment\nwhere you are.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your location is used only to resolve local time, timezone and today’s celestial timing.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      FilledButton.icon(
                        key: const Key('allow_location'),
                        onPressed: () => setState(() => _step = 1),
                        icon: const Icon(Icons.near_me_rounded),
                        label: const Text('Allow Current Location'),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => setState(() => _step = 1),
                        child: const Text('Use Device Time Zone Instead'),
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
            child: ZodiacAvatar(
              size: 92,
              glow: true,
              sign: zodiacForDate(_birthDate),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              zodiacForDate(_birthDate).label.toUpperCase(),
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
                        '${_birthDate.month}/${_birthDate.day}/${_birthDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Birth time unknown'),
              subtitle: const Text(
                'We will compare possible birth-hour patterns.',
              ),
              value: _birthTimeUnknown,
              onChanged: (value) => setState(() => _birthTimeUnknown = value),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: const InputDecoration(labelText: 'Country of birth'),
            items:
                const [
                      'United States',
                      'United Kingdom',
                      'Germany',
                      'Japan',
                      'Vietnam',
                    ]
                    .map(
                      (country) => DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      ),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _country = value ?? _country),
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
