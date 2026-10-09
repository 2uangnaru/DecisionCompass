import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../data/country_names_data.dart';
import '../theme.dart';

/// Flag emoji converter from 2-letter ISO country code.
String _countryCodeToEmoji(String countryCode) {
  if (countryCode.length != 2) return '';
  final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
  final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
  return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
}

/// Strips Vietnamese and Latin diacritics for flexible accent-insensitive search.
String _stripDiacritics(String text) {
  var str = text;
  str = str.replaceAll(RegExp(r'[àáảãạâầấẩẫậăằắẳẵặ]'), 'a');
  str = str.replaceAll(RegExp(r'[ÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶ]'), 'A');
  str = str.replaceAll(RegExp(r'[èéẻẽẹêềếểễệ]'), 'e');
  str = str.replaceAll(RegExp(r'[ÈÉẺẼẸÊỀẾỂỄỆ]'), 'E');
  str = str.replaceAll(RegExp(r'[ìíỉĩị]'), 'i');
  str = str.replaceAll(RegExp(r'[ÌÍỈĨỊ]'), 'I');
  str = str.replaceAll(RegExp(r'[òóỏõọôồốổỗộơờớởỡợ]'), 'o');
  str = str.replaceAll(RegExp(r'[ÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ]'), 'O');
  str = str.replaceAll(RegExp(r'[ùúủũụưừứửữự]'), 'u');
  str = str.replaceAll(RegExp(r'[ÙÚỦŨỤƯỪỨỬỮỰ]'), 'U');
  str = str.replaceAll(RegExp(r'[ỳýỷỹỵ]'), 'y');
  str = str.replaceAll(RegExp(r'[ỲÝỶỸỴ]'), 'Y');
  str = str.replaceAll(RegExp(r'[đ]'), 'd');
  str = str.replaceAll(RegExp(r'[Đ]'), 'D');
  return str;
}

/// Common country search aliases so searching in any supported language
/// or common variant instantly resolves to the target country.
const Map<String, List<String>> _countrySearchAliases = {
  'KR': [
    'korea',
    'south korea',
    'republic of korea',
    'rok',
    'han quoc',
    'hàn quốc',
    'nam trieu tien',
    'nam triều tiên',
  ],
  'KP': [
    'north korea',
    'democratic people\'s republic of korea',
    'dprk',
    'trieu tien',
    'triều tiên',
    'bac trieu tien',
    'bắc triều tiên',
  ],
  'VN': ['vietnam', 'viet nam', 'việt nam'],
  'US': ['usa', 'united states', 'america', 'my', 'mỹ', 'hoa ky', 'hoa kỳ'],
  'GB': [
    'uk',
    'united kingdom',
    'great britain',
    'england',
    'anh',
    'vuong quoc anh',
  ],
  'CN': ['china', 'trung quoc', 'trung quốc'],
  'JP': ['japan', 'nhat ban', 'nhật bản'],
  'DE': ['germany', 'duc', 'đức'],
  'FR': ['france', 'phap', 'pháp'],
  'RU': ['russia', 'nga', 'lien bang nga'],
  'LA': ['laos', 'lao'],
  'KH': ['cambodia', 'campuchia', 'cam pu chia'],
  'TH': ['thailand', 'thai lan', 'thái lan'],
  'SG': ['singapore'],
  'MY': ['malaysia', 'ma lai xi a'],
  'ID': ['indonesia', 'in do ne xi a'],
  'PH': ['philippines', 'phi lip pin'],
  'IN': ['india', 'an do', 'ấn độ'],
  'AU': ['australia', 'uc', 'úc'],
  'CA': ['canada'],
};

/// Shows an enhanced country picker that:
/// 1. Names Korea as "Korea" in English (not "South Korea") and places it under 'K'.
/// 2. Sorts countries alphabetically according to the localized display name.
/// 3. Provides accent-insensitive search and matches aliases (e.g. "Korea", "South Korea", "Hàn Quốc").
void showCompassCountryPicker({
  required BuildContext context,
  required ValueChanged<Country> onSelect,
  VoidCallback? onClosed,
  List<String>? favorite,
  List<String>? exclude,
  List<String>? countryFilter,
  bool showPhoneCode = false,
  CustomFlagBuilder? customFlagBuilder,
  CountryListThemeData? countryListTheme,
  bool searchAutofocus = false,
  bool showWorldWide = false,
  bool showSearch = true,
  bool showDragHandle = true,
  bool useSafeArea = false,
  bool useRootNavigator = false,
  bool moveAlongWithKeyboard = false,
  Widget header = const SizedBox.shrink(),
}) {
  final shape = RoundedRectangleBorder(
    borderRadius:
        countryListTheme?.borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(24)),
  );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: countryListTheme?.backgroundColor ?? CompassColors.raised,
    shape: shape,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    useRootNavigator: useRootNavigator,
    builder: (ctx) {
      final deviceHeight = MediaQuery.of(ctx).size.height;
      final statusBarHeight = MediaQuery.of(ctx).padding.top;
      final height =
          countryListTheme?.bottomSheetHeight ??
          deviceHeight - (statusBarHeight + (kToolbarHeight / 1.5));
      final width = countryListTheme?.bottomSheetWidth;

      return Padding(
        padding:
            moveAlongWithKeyboard
                ? MediaQuery.of(ctx).viewInsets
                : EdgeInsets.zero,
        child: Container(
          height: height,
          width: width,
          padding: countryListTheme?.padding,
          margin: countryListTheme?.margin,
          child: _CompassCountryListView(
            onSelect: onSelect,
            favorite: favorite,
            exclude: exclude,
            countryFilter: countryFilter,
            showPhoneCode: showPhoneCode,
            countryListTheme: countryListTheme,
            searchAutofocus: searchAutofocus,
            showWorldWide: showWorldWide,
            showSearch: showSearch,
            customFlagBuilder: customFlagBuilder,
            header: header,
          ),
        ),
      );
    },
  ).whenComplete(() {
    if (onClosed != null) onClosed();
  });
}

/// Drop-in alias matching `package:country_picker` function signature.
void showCountryPicker({
  required BuildContext context,
  required ValueChanged<Country> onSelect,
  VoidCallback? onClosed,
  List<String>? favorite,
  List<String>? exclude,
  List<String>? countryFilter,
  bool showPhoneCode = false,
  CustomFlagBuilder? customFlagBuilder,
  CountryListThemeData? countryListTheme,
  bool searchAutofocus = false,
  bool showWorldWide = false,
  bool showSearch = true,
  bool showDragHandle = true,
  bool useSafeArea = false,
  bool useRootNavigator = false,
  bool moveAlongWithKeyboard = false,
  Widget header = const SizedBox.shrink(),
}) => showCompassCountryPicker(
  context: context,
  onSelect: onSelect,
  onClosed: onClosed,
  favorite: favorite,
  exclude: exclude,
  countryFilter: countryFilter,
  showPhoneCode: showPhoneCode,
  customFlagBuilder: customFlagBuilder,
  countryListTheme: countryListTheme,
  searchAutofocus: searchAutofocus,
  showWorldWide: showWorldWide,
  showSearch: showSearch,
  showDragHandle: showDragHandle,
  useSafeArea: useSafeArea,
  useRootNavigator: useRootNavigator,
  moveAlongWithKeyboard: moveAlongWithKeyboard,
  header: header,
);

class _CompassCountryListView extends StatefulWidget {
  const _CompassCountryListView({
    required this.onSelect,
    this.favorite,
    this.exclude,
    this.countryFilter,
    required this.showPhoneCode,
    this.countryListTheme,
    required this.searchAutofocus,
    required this.showWorldWide,
    required this.showSearch,
    this.customFlagBuilder,
    required this.header,
  });

  final ValueChanged<Country> onSelect;
  final List<String>? favorite;
  final List<String>? exclude;
  final List<String>? countryFilter;
  final bool showPhoneCode;
  final CountryListThemeData? countryListTheme;
  final bool searchAutofocus;
  final bool showWorldWide;
  final bool showSearch;
  final CustomFlagBuilder? customFlagBuilder;
  final Widget header;

  @override
  State<_CompassCountryListView> createState() =>
      _CompassCountryListViewState();
}

class _CompassCountryListViewState extends State<_CompassCountryListView> {
  late final TextEditingController _searchController;
  late final List<Country> _allCountries;
  List<Country>? _favoriteList;
  List<Country> _filteredList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Load countries, normalising KR's name to Korea
    final rawCountries = CountryService().getAll();
    final countries = <Country>[];
    for (final c in rawCountries) {
      if (c.countryCode == 'KR') {
        countries.add(
          Country(
            phoneCode: c.phoneCode,
            countryCode: 'KR',
            e164Sc: c.e164Sc,
            geographic: c.geographic,
            level: c.level,
            name: 'Korea',
            example: c.example,
            displayName: 'Korea (KR) [+${c.phoneCode}]',
            displayNameNoCountryCode: 'Korea (KR)',
            e164Key: c.e164Key,
            fullExampleWithPlusSign: c.fullExampleWithPlusSign,
          ),
        );
      } else {
        countries.add(c);
      }
    }

    if (!widget.showPhoneCode) {
      final ids = <String>{};
      countries.retainWhere((country) => ids.add(country.countryCode));
    }

    if (widget.exclude != null) {
      countries.removeWhere(
        (country) => widget.exclude!.contains(country.countryCode),
      );
    }

    if (widget.countryFilter != null) {
      countries.removeWhere(
        (country) => !widget.countryFilter!.contains(country.countryCode),
      );
    }

    _allCountries = countries;

    if (widget.favorite != null) {
      _favoriteList = _allCountries
          .where((c) => widget.favorite!.contains(c.countryCode))
          .toList();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filterList(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _displayName(Country country, CountryLocalizations? localizations) {
    return localizations?.countryName(countryCode: country.countryCode) ??
        country.name;
  }

  bool _matchesCountry(
    Country country,
    String query,
    String queryNorm,
    CountryLocalizations? localizations,
  ) {
    final cleanPhone = query.startsWith('+') ? query.substring(1) : query;
    if (country.phoneCode.startsWith(cleanPhone)) return true;
    if (country.countryCode.toLowerCase().startsWith(query)) return true;

    final locName = _displayName(country, localizations).toLowerCase();
    if (locName.contains(query)) return true;
    if (_stripDiacritics(locName).contains(queryNorm)) return true;

    final engName = country.name.toLowerCase();
    if (engName.contains(query)) return true;
    if (_stripDiacritics(engName).contains(queryNorm)) return true;

    // Vietnamese name from CLDR (searchable in any locale, with or without accents)
    final viName = countryNamesVI[country.countryCode]?.toLowerCase();
    if (viName != null) {
      if (viName.contains(query)) return true;
      if (_stripDiacritics(viName).contains(queryNorm)) return true;
    }

    final aliases = _countrySearchAliases[country.countryCode];
    if (aliases != null) {
      for (final alias in aliases) {
        if (alias.contains(query) ||
            _stripDiacritics(alias).contains(queryNorm)) {
          return true;
        }
      }
    }

    return false;
  }

  void _filterList(String query) {
    final localizations = CountryLocalizations.of(context);
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      final sorted = List<Country>.from(_allCountries);
      sorted.sort((a, b) {
        final nameA = _displayName(a, localizations).trim().toLowerCase();
        final nameB = _displayName(b, localizations).trim().toLowerCase();
        return nameA.compareTo(nameB);
      });
      setState(() {
        _isSearching = false;
        _filteredList = sorted;
      });
      return;
    }

    final q = trimmed.toLowerCase();
    final qNorm = _stripDiacritics(q);

    final matches = _allCountries
        .where((c) => _matchesCountry(c, q, qNorm, localizations))
        .toList();

    matches.sort((a, b) {
      final nameA = _displayName(a, localizations).toLowerCase();
      final nameB = _displayName(b, localizations).toLowerCase();
      final normA = _stripDiacritics(nameA);
      final normB = _stripDiacritics(nameB);

      // Exact ISO code match takes top priority (e.g. 'KR' or 'VN')
      final exactA = a.countryCode.toLowerCase() == q;
      final exactB = b.countryCode.toLowerCase() == q;
      if (exactA && !exactB) return -1;
      if (!exactA && exactB) return 1;

      // Prefix match on localized or English name
      final startsA =
          nameA.startsWith(q) ||
          normA.startsWith(qNorm) ||
          a.name.toLowerCase().startsWith(q);
      final startsB =
          nameB.startsWith(q) ||
          normB.startsWith(qNorm) ||
          b.name.toLowerCase().startsWith(q);
      if (startsA && !startsB) return -1;
      if (!startsA && startsB) return 1;

      return nameA.compareTo(nameB);
    });

    setState(() {
      _isSearching = true;
      _filteredList = matches;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchLabel =
        CountryLocalizations.of(context)?.countryName(countryCode: 'search') ??
        'Search';

    final textStyle =
        widget.countryListTheme?.textStyle ??
        const TextStyle(fontSize: 16, color: CompassColors.text);

    return Column(
      children: [
        const SizedBox(height: 12),
        widget.header,
        if (widget.showSearch)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: TextField(
              autofocus: widget.searchAutofocus,
              controller: _searchController,
              style:
                  widget.countryListTheme?.searchTextStyle ??
                  const TextStyle(color: CompassColors.text),
              decoration:
                  widget.countryListTheme?.inputDecoration ??
                  InputDecoration(
                    labelText: searchLabel,
                    hintText: searchLabel,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
                      ),
                    ),
                  ),
              onChanged: _filterList,
            ),
          ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (_favoriteList != null && !_isSearching) ...[
                for (final country in _favoriteList!)
                  _buildListRow(country, textStyle),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Divider(thickness: 1),
                ),
              ],
              for (final country in _filteredList)
                _buildListRow(country, textStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListRow(Country country, TextStyle textStyle) {
    final localizations = CountryLocalizations.of(context);
    final displayName = _displayName(country, localizations);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onSelect(country);
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: [
              const SizedBox(width: 20),
              _flagWidget(country),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  displayName.replaceAll(RegExp(r'\s+'), ' '),
                  style: textStyle,
                ),
              ),
              if (widget.showPhoneCode) ...[
                Text(
                  '+${country.phoneCode}',
                  style: const TextStyle(color: CompassColors.muted),
                ),
                const SizedBox(width: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _flagWidget(Country country) {
    if (widget.customFlagBuilder != null) {
      return widget.customFlagBuilder!(country);
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      width: isRtl ? 50 : 44,
      child: Text(
        country.iswWorldWide
            ? '\uD83C\uDF0D'
            : _countryCodeToEmoji(country.countryCode),
        style: TextStyle(
          fontSize: widget.countryListTheme?.flagSize ?? 25,
          fontFamilyFallback: widget.countryListTheme?.emojiFontFamilyFallback,
        ),
      ),
    );
  }
}
