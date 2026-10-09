import 'dart:async';

import 'package:country_picker/country_picker.dart' hide showCountryPicker;

import '../widgets/compass_country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_profile.dart';
import '../data/profile_edit_policy.dart';
import '../l10n/app_localizations.dart';
import '../local_engine/time/tzdb.dart';
import '../localized_presentation.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../models.dart';
import '../widgets/birth_date_picker.dart';
import '../widgets/birth_time_picker.dart';
import '../widgets/celestial_ui.dart';

/// Cancel and Save, side by side, exactly the same size.
///
/// Equal width comes from two [Expanded]s; equal height from [IntrinsicHeight]
/// plus `CrossAxisAlignment.stretch`, so a label that wraps at a large text
/// scale grows *both* boxes rather than leaving one short. Each button's
/// `minimumSize` is restated locally: the app-wide themes ask for an infinite
/// minimum width, which inside an `Expanded` would be an unbounded-constraint
/// fight rather than a layout.
class _ConfirmActions extends StatelessWidget {
  const _ConfirmActions({required this.dialogContext, required this.l10n});

  final BuildContext dialogContext;
  final AppLocalizations l10n;

  /// Android's minimum accessible touch target, and the floor for both boxes.
  static const double _minHeight = 48;

  static const ButtonStyle _shared = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, _minHeight)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget label(String text) => Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('profile_confirm_cancel'),
              style: _shared,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: label(l10n.cancelAction),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              key: const Key('profile_confirm_save'),
              style: _shared,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: label(l10n.saveAction),
            ),
          ),
        ],
      ),
    );
  }
}

/// The saved profile, and the three parts of it a reader may correct.
///
/// Pops with the saved [AppProfile] when something was written, and with null
/// when the reader left without saving. The caller is what carries the new
/// profile into Home and the reading flow — this page never reaches past the
/// repository on its own.
///
/// The birth date is editable too, but on the longest leash of the three.
/// Every cycle a reading is built from is anchored to it, so changing it is
/// the nearest thing the app has to becoming a different person — and yet a
/// reader who typed it wrong during onboarding has a compass built for
/// somebody else until they can fix it. A new profile opens the date after
/// two hours; every change after that closes it for four.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.dependencies,
  });

  final AppProfile profile;
  final ReadingDependencies dependencies;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final _nameController = TextEditingController(
    text: widget.profile.userName ?? '',
  );
  final _nameFocusNode = FocusNode();

  late bool _knowsBirthTime = widget.profile.birthTime != null;
  late TimeOfDay? _birthTime = _parseBirthTime(widget.profile.birthTime);
  late String _birthCountryCode = widget.profile.birthCountryCode;
  late DateTime _birthDate = widget.profile.birthDate;

  /// True while the profile is being written. A second tap is ignored, the
  /// way onboarding's own create button ignores one.
  var _saving = false;
  var _saveFailed = false;

  /// The locked-field notice currently on screen, or null for none.
  ///
  /// The page owns it rather than `ScaffoldMessenger`, because the messenger
  /// is a *queue*: ten taps on a held field put ten identical notices in it,
  /// which then came up one after another over the Cancel and Save buttons
  /// long after the reader had stopped tapping. There is only ever one of
  /// these, and it is gone with the page.
  String? _notice;
  Timer? _noticeTimer;

  /// True while the notice is up and not yet on its way out. A repeat tap is
  /// only ignored while this holds; once it is fading, asking again brings it
  /// back.
  bool _noticeHolding = false;

  /// Long enough to read a short sentence, short enough not to sit over the
  /// screen while the reader carries on.
  static const Duration _noticeDuration = Duration(milliseconds: 3500);

  /// It arrives the way a message arrives — in from the left as it fades up —
  /// and leaves by fading alone. Sliding back out would read as the notice
  /// retreating, which is a different and more deliberate gesture than
  /// something quietly finishing.
  late final AnimationController _noticeAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _noticeFade = CurvedAnimation(
    parent: _noticeAnimation,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  /// `Threshold(0)` on the way back holds this at its end value for the whole
  /// reverse, so the fade-out happens where the notice already is.
  late final Animation<Offset> _noticeSlide =
      Tween<Offset>(begin: const Offset(-0.18, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _noticeAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: const Threshold(0),
        ),
      );

  /// Fires when a cooldown runs out, so a reader waiting on this screen sees
  /// the field open by itself rather than having to leave and come back.
  /// One-shot, never periodic: a repeating timer would keep the frame loop
  /// awake for hours and would hang any test that settles the tree.
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _scheduleCooldownExpiry();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    // Nothing of this page outlives it — including a notice that would
    // otherwise have been handed to the messenger and shown on Home.
    _noticeTimer?.cancel();
    _noticeAnimation.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

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

  // --------------------------------------------------------------- state --

  DateTime get _nowUtc => widget.dependencies.nowUtc().toUtc();

  ZodiacSign get _zodiac => zodiacForDate(_birthDate);

  Duration get _birthTimeWait => remainingEditCooldown(
    changedAtUtc: widget.profile.birthTimeChangedAtUtc,
    window: birthTimeEditCooldown,
    nowUtc: _nowUtc,
  );

  Duration get _birthCountryWait => remainingEditCooldown(
    changedAtUtc: widget.profile.birthCountryChangedAtUtc,
    window: birthCountryEditCooldown,
    nowUtc: _nowUtc,
  );

  /// Measured from the last change, or — before there has been one — from
  /// when the profile was created. See `remainingBirthDateWait`.
  Duration get _birthDateWait => remainingBirthDateWait(
    createdAt: widget.profile.createdAt,
    changedAtUtc: widget.profile.birthDateChangedAtUtc,
    nowUtc: _nowUtc,
  );

  bool get _birthTimeLocked => _birthTimeWait > Duration.zero;
  bool get _birthCountryLocked => _birthCountryWait > Duration.zero;
  bool get _birthDateLocked => _birthDateWait > Duration.zero;

  /// Wakes the screen up exactly when the nearer of the two waits ends.
  void _scheduleCooldownExpiry() {
    _cooldownTimer?.cancel();
    final waits = [
      _birthTimeWait,
      _birthCountryWait,
      _birthDateWait,
    ].where((wait) => wait > Duration.zero);
    if (waits.isEmpty) return;
    final next = waits.reduce((a, b) => a < b ? a : b);
    _cooldownTimer = Timer(next, () {
      if (mounted) setState(_scheduleCooldownExpiry);
    });
  }

  /// The engine's `HH:mm`, or null for an unknown birth time.
  String? get _birthTimeValue {
    final time = _knowsBirthTime ? _birthTime : null;
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// The typed name, or null for the default-name state. Null rather than the
  /// translated word, for the reason `AppProfile.userName` documents.
  String? get _nameValue {
    final typed = _nameController.text.trim();
    return typed.isEmpty ? null : typed;
  }

  bool get _nameChanged => _nameValue != widget.profile.userName;
  bool get _birthTimeChanged => _birthTimeValue != widget.profile.birthTime;
  bool get _birthCountryChanged =>
      _birthCountryCode != widget.profile.birthCountryCode;

  /// By calendar day, never by instant — see [isSameBirthDate].
  bool get _birthDateChanged =>
      !isSameBirthDate(_birthDate, widget.profile.birthDate);

  bool get _hasChanges =>
      _nameChanged ||
      _birthTimeChanged ||
      _birthCountryChanged ||
      _birthDateChanged;

  // ---------------------------------------------------------------- edits --

  /// Says how long is left, without pretending the tap did anything.
  void _reportLocked(String message) {
    _unfocus();
    // Re-read the clock on the way through: the inline label was rendered
    // whenever this page last built, and the reader may have been sitting
    // here since.
    setState(_scheduleCooldownExpiry);
    _showNotice(message);
  }

  /// Puts [message] at the top of the page, replacing whatever was there.
  ///
  /// A repeat of the message already showing does nothing at all — not even
  /// restart its countdown. That is what makes ten taps on one held field one
  /// notice rather than ten, and it leaves nothing queued to appear after the
  /// reader has moved on. A *different* field replaces the text immediately,
  /// because the reader's question has changed.
  void _showNotice(String message) {
    if (_noticeHolding && _notice == message) return;
    _noticeTimer?.cancel();
    setState(() {
      _notice = message;
      _noticeHolding = true;
    });
    if (_reducedMotion) {
      _noticeAnimation.value = 1;
    } else {
      // From zero even when one is already up: a different field's message is
      // a new message, and it should look like one arriving.
      _noticeAnimation.forward(from: 0);
    }
    _noticeTimer = Timer(_noticeDuration, _hideNotice);
  }

  void _hideNotice() {
    if (!mounted || _notice == null) return;
    _noticeHolding = false;
    if (_reducedMotion) {
      _noticeAnimation.value = 0;
      setState(() => _notice = null);
      return;
    }
    _noticeAnimation.reverse().then((_) {
      // Guarded: a tap during the fade restarts the animation, and that run's
      // future still completes here. Only a controller that actually reached
      // the bottom means the notice is gone.
      if (mounted && _noticeAnimation.value == 0) {
        setState(() => _notice = null);
      }
    });
  }

  bool get _reducedMotion => MediaQuery.of(context).disableAnimations;

  /// The notice, floating over the top of the scrolling area.
  ///
  /// In a [Stack] rather than in the column it used to head, because taking
  /// space changed the height of everything below it: the whole page stepped
  /// down when a notice arrived and back up when it left, which read as the
  /// screen flinching rather than as something being said. Nothing moves now.
  ///
  /// Its position is the Stack's own top edge, which is immediately below the
  /// pinned Back row — a relationship rather than a measured offset, so it
  /// cannot drift when the title wraps or the text scale changes.
  ///
  /// [IgnorePointer] because it explains a tap rather than inviting one: the
  /// fields underneath stay reachable while it is up.
  Widget _noticeOverlay() {
    final message = _notice;
    if (message == null) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _noticeFade,
          child: SlideTransition(
            position: _noticeSlide,
            child: Semantics(
              container: true,
              liveRegion: true,
              label: message,
              excludeSemantics: true,
              child: Container(
                key: const Key('profile_locked_notice'),
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CompassColors.raised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CompassColors.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 18,
                        color: CompassColors.gold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Wraps rather than ellipsizes: the sentence carries the
                    // number the reader is waiting for, and at a large text
                    // scale on a narrow phone it will not fit on one line.
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: CompassColors.text, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate(AppLocalizations l10n, String locale) async {
    if (_birthDateLocked) {
      _reportLocked(
        l10n.profileBirthDateLocked(
          formatEditWait(l10n, locale, _birthDateWait),
        ),
      );
      return;
    }
    _unfocus();
    // The onboarding picker, with its own range and validation: a date this
    // screen accepts has to be a date onboarding would have accepted.
    final picked = await showBirthDatePicker(
      context: context,
      initialDate: _birthDate,
    );
    if (!mounted || picked == null) return;
    setState(() => _birthDate = picked);
  }

  Future<void> _pickBirthTime(AppLocalizations l10n, String localeName) async {
    if (_birthTimeLocked) {
      _reportLocked(
        l10n.profileBirthTimeLocked(
          formatEditWait(l10n, localeName, _birthTimeWait),
        ),
      );
      return;
    }
    _unfocus();
    final picked = await showBirthTimePicker(
      context: context,
      helpText: l10n.selectBirthTime,
      current: _birthTime,
    );
    // Null is "no answer": cancelled, or dismissed without completing a
    // choice. The field keeps whatever it already said — including Unknown —
    // and nothing is written, so no cooldown can start from a dismissal.
    if (!mounted || picked == null) return;
    setState(() {
      _birthTime = picked;
      // Confirming a time *is* the answer to "do you know it?". The row is
      // reachable while the switch is off, so without this the reader picked
      // an hour, watched the sheet close, and found Unknown still sitting
      // there: the selection was read back through the switch and discarded.
      // The switch stays as the other way to say the same thing.
      _knowsBirthTime = true;
    });
  }

  void _setKnowsBirthTime(bool value, AppLocalizations l10n, String locale) {
    if (_birthTimeLocked) {
      _reportLocked(
        l10n.profileBirthTimeLocked(
          formatEditWait(l10n, locale, _birthTimeWait),
        ),
      );
      return;
    }
    _unfocus();
    setState(() {
      _knowsBirthTime = value;
      // Dropped rather than held aside, exactly as onboarding does it: a
      // reader who says they do not know their birth time must not have an
      // earlier answer restored for them.
      _birthTime = value ? _parseBirthTime(widget.profile.birthTime) : null;
    });
  }

  void _pickBirthCountry(AppLocalizations l10n, String localeName) {
    if (_birthCountryLocked) {
      _reportLocked(
        l10n.profileBirthCountryLocked(
          formatEditWait(l10n, localeName, _birthCountryWait),
        ),
      );
      return;
    }
    _unfocus();
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      showSearch: true,
      searchAutofocus: true,
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
        setState(() => _birthCountryCode = country.countryCode);
      },
    );
  }

  // ----------------------------------------------------------------- save --

  /// Names the cooldowns this save is about to start, and asks.
  ///
  /// Only for the fields that actually changed: a reader editing their name
  /// is not told about a birth-time lock that is not going to happen.
  Future<bool> _confirm(AppLocalizations l10n) async {
    // One line per field actually changing, in the order the screen shows
    // them. A reader editing only their name is told about no lock at all.
    final consequences = <String>[
      if (_birthDateChanged) l10n.profileConfirmBirthDate,
      if (_birthTimeChanged) l10n.profileConfirmBirthTime,
      if (_birthCountryChanged) l10n.profileConfirmBirthCountry,
    ];
    if (consequences.isEmpty) return true;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('profile_confirm_dialog'),
        backgroundColor: CompassColors.raised,
        title: Text(l10n.profileConfirmTitle),
        // `AlertDialog` gives `content` a bounded height, so the scroll view
        // only bites on a short screen or at a large text scale. It is here
        // rather than `scrollable: true` because that would put the buttons
        // inside the same scroll view and scroll them off the screen.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in consequences) ...[
                Text(line),
                const SizedBox(height: 10),
              ],
              Text(
                l10n.profileReadingsUnchanged,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: CompassColors.muted),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        // One action, which is itself the row.
        //
        // Two separate actions go into `OverflowBar`, and this app's button
        // themes set `minimumSize: Size.fromHeight(56)` — which is
        // `Size(infinity, 56)`, a minimum *width* of infinity. Every button
        // therefore claims the whole line, the two cannot sit side by side,
        // and `OverflowBar` does what it is supposed to do and stacks them.
        // That is where Cancel-above-a-full-width-Save came from.
        actions: [_ConfirmActions(dialogContext: dialogContext, l10n: l10n)],
      ),
    );
    return agreed ?? false;
  }

  Future<void> _save() async {
    _unfocus();
    if (_saving || !_hasChanges) return;
    final l10n = AppLocalizations.of(context);
    // Read before the dialog, and read again for the stamps afterwards, so a
    // slow reader's cooldown starts from the save and not from the question.
    final birthTimeChanged = _birthTimeChanged;
    final birthCountryChanged = _birthCountryChanged;
    final birthDateChanged = _birthDateChanged;
    if (!await _confirm(l10n)) return;
    if (!mounted) return;

    final now = _nowUtc;
    final next = widget.profile.edited(
      userName: _nameValue,
      birthDate: _birthDate,
      birthTime: _birthTimeValue,
      birthCountryCode: _birthCountryCode,
      // Only a field that actually changed restarts its own wait. A save that
      // only renamed the reader, or one that re-picked the hour already
      // stored, leaves the old stamp exactly where it was.
      birthTimeChangedAtUtc: birthTimeChanged
          ? now
          : widget.profile.birthTimeChangedAtUtc,
      birthCountryChangedAtUtc: birthCountryChanged
          ? now
          : widget.profile.birthCountryChangedAtUtc,
      birthDateChangedAtUtc: birthDateChanged
          ? now
          : widget.profile.birthDateChangedAtUtc,
    );

    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.dependencies.profileRepository.save(next);
    } catch (_) {
      // Nothing was written, so nothing has changed — including the cooldown,
      // which lives in the same record. The reader keeps their edits and can
      // try again.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
      return;
    }
    if (!mounted) return;

    // Through the messenger rather than this page's own context: the notice
    // has to outlive the pop to be read on Home.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('profile_saved_notice'),
        content: Text(l10n.profileSaved),
      ),
    );
    // The reading flow's copy of the profile is the caller's to update; this
    // page hands it back rather than reaching into Home.
    Navigator.of(context).pop(next);
  }

  // ---------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = intlLocaleOf(context);
    final country = Country.tryParse(_birthCountryCode);

    return PopScope(
      // Only while a write is in flight. `Navigator.pop` is not gated by
      // this — only `maybePop` is, and that is the path the system Back
      // button and the back gesture take — so the pop that hands the saved
      // profile back at the end of `_save` still goes through.
      //
      // Without it, Back could pop the page mid-write: the record would land
      // in storage while Home carried on with the profile it was built with,
      // and the two would not agree again until the app restarted.
      canPop: !_saving,
      child: CelestialScaffold(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _unfocus,
          child: Column(
            children: [
              // Pinned above the scrolling area rather than scrolling with
              // it. That is what gives the notice a fixed edge to hang from,
              // and it is why Back can never be covered: the notice lives in
              // the area below this row and cannot reach back into it.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('profile_back'),
                      // Leaving without saving is the cancel: nothing has been
                      // written, so no cooldown starts and no reading changes.
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: l10n.backAction,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.profileTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                // The sign the *edited* date gives, so a reader
                                // correcting their birthday watches the avatar follow
                                // before they commit to it rather than after.
                                ZodiacAvatar(
                                  size: 92,
                                  glow: true,
                                  sign: _zodiac,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  zodiacLabel(l10n, _zodiac),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: CompassColors.gold,
                                        letterSpacing: 1.7,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            key: const Key('profile_name_field'),
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            onTapOutside: (_) => _unfocus(),
                            textInputAction: TextInputAction.done,
                            // So Save wakes up as soon as the first character lands.
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: l10n.nameField,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _editableRow(
                            cardKey: const Key('profile_birth_date'),
                            icon: Icons.calendar_month_rounded,
                            label: l10n.dateOfBirth,
                            value: formatDate(localeName, _birthDate),
                            valueKey: const Key('profile_birth_date_value'),
                            locked: _birthDateLocked,
                            note: _birthDateLocked
                                ? l10n.profileBirthDateLocked(
                                    formatEditWait(
                                      l10n,
                                      localeName,
                                      _birthDateWait,
                                    ),
                                  )
                                : null,
                            noteKey: const Key('profile_birth_date_wait'),
                            onTap: () => _pickBirthDate(l10n, localeName),
                          ),
                          const SizedBox(height: 14),
                          _birthTimeSection(l10n, localeName),
                          const SizedBox(height: 14),
                          _editableRow(
                            cardKey: const Key('profile_birth_country'),
                            icon: Icons.public_rounded,
                            label: l10n.countryOfBirth,
                            value:
                                country?.getTranslatedName(context) ??
                                country?.name ??
                                _birthCountryCode,
                            valueKey: const Key('profile_birth_country_value'),
                            locked: _birthCountryLocked,
                            note: _birthCountryLocked
                                ? l10n.profileBirthCountryLocked(
                                    formatEditWait(
                                      l10n,
                                      localeName,
                                      _birthCountryWait,
                                    ),
                                  )
                                : null,
                            noteKey: const Key('profile_birth_country_wait'),
                            onTap: () => _pickBirthCountry(l10n, localeName),
                          ),
                          const SizedBox(height: 22),
                          if (_saveFailed) ...[
                            Text(
                              l10n.profileNotSaved,
                              key: const Key('profile_save_failed'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('profile_cancel'),
                                  onPressed: _saving
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: Text(l10n.cancelAction),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  key: const Key('profile_save'),
                                  // Dead until something actually differs: a save with
                                  // nothing to save would be a write, and a write is what
                                  // starts a cooldown.
                                  onPressed: (_saving || !_hasChanges)
                                      ? null
                                      : _save,
                                  child: Text(l10n.saveAction),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.profileReadingsUnchanged,
                            key: const Key('profile_history_note'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: CompassColors.muted),
                          ),
                        ],
                      ),
                    ),
                    _noticeOverlay(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _birthTimeSection(AppLocalizations l10n, String localeName) {
    final locked = _birthTimeLocked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: SwitchListTile.adaptive(
            key: const Key('profile_knows_birth_time'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.knowBirthTime),
            subtitle: Text(
              _knowsBirthTime
                  ? l10n.knowBirthTimeDetail
                  : l10n.birthTimeUnknownDetail,
            ),
            value: _knowsBirthTime,
            // Still live while locked, and still says why. A dead switch
            // would leave a reader tapping at nothing with no explanation.
            onChanged: (value) => _setKnowsBirthTime(value, l10n, localeName),
          ),
        ),
        const SizedBox(height: 10),
        _editableRow(
          cardKey: const Key('profile_birth_time'),
          icon: Icons.schedule_rounded,
          label: l10n.timeOfBirth,
          value: _knowsBirthTime
              ? (_birthTime == null
                    ? l10n.selectBirthTime
                    : formatClock(
                        localeName,
                        _birthTime!.hour,
                        _birthTime!.minute,
                      ))
              : l10n.profileBirthTimeUnknownValue,
          valueKey: const Key('profile_birth_time_value'),
          locked: locked,
          note: locked
              ? l10n.profileBirthTimeLocked(
                  formatEditWait(l10n, localeName, _birthTimeWait),
                )
              : null,
          noteKey: const Key('profile_birth_time_wait'),
          onTap: () => _pickBirthTime(l10n, localeName),
        ),
      ],
    );
  }

  Widget _editableRow({
    required Key cardKey,
    required IconData icon,
    required String label,
    required String value,
    required Key valueKey,
    required bool locked,
    required String? note,
    required Key noteKey,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          key: cardKey,
          // Tappable even while locked, so the tap can explain itself.
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: locked ? CompassColors.muted : CompassColors.gold,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      key: valueKey,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: locked
                            ? CompassColors.secondary
                            : CompassColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                locked
                    ? Icons.hourglass_bottom_rounded
                    : Icons.chevron_right_rounded,
                color: locked ? CompassColors.muted : null,
                size: locked ? 18 : null,
              ),
            ],
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              note,
              key: noteKey,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: CompassColors.gold),
            ),
          ),
      ],
    );
  }
}
