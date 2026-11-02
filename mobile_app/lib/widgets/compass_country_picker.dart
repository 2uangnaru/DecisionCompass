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

/// Each accented letter the search folds, keyed by its code unit.
final Map<int, String> _diacriticFold = () {
  const groups = <String, String>{
    'a': 'àáảãạâầấẩẫậăằắẳẵặ',
    'A': 'ÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶ',
    'e': 'èéẻẽẹêềếểễệ',
    'E': 'ÈÉẺẼẸÊỀẾỂỄỆ',
    'i': 'ìíỉĩị',
    'I': 'ÌÍỈĨỊ',
    'o': 'òóỏõọôồốổỗộơờớởỡợ',
    'O': 'ÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ',
    'u': 'ùúủũụưừứửữự',
    'U': 'ÙÚỦŨỤƯỪỨỬỮỰ',
    'y': 'ỳýỷỹỵ',
    'Y': 'ỲÝỶỸỴ',
    'd': 'đ',
    'D': 'Đ',
  };
  return <int, String>{
    for (final MapEntry(key: base, value: letters) in groups.entries)
      for (final unit in letters.codeUnits) unit: base,
  };
}();

/// Strips Vietnamese and Latin diacritics for flexible accent-insensitive
/// search. One pass, no regular expressions: it runs for every country when
/// the sheet opens.
String _stripDiacritics(String text) {
  final out = StringBuffer();
  for (final unit in text.codeUnits) {
    final folded = _diacriticFold[unit];
    if (folded != null) {
      out.write(folded);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}

final RegExp _whitespaceRun = RegExp(r'\s+');

/// Everything search and sorting read about one country, worked out once per
/// language instead of on every keystroke and every comparison.
class _SearchEntry {
  _SearchEntry(this.country, this.displayName)
    : name = displayName.toLowerCase(),
      english = country.name.toLowerCase(),
      vietnamese = countryNamesVI[country.countryCode]?.toLowerCase(),
      code = country.countryCode.toLowerCase(),
      sortKey = displayName.trim().toLowerCase(),
      label = displayName.replaceAll(_whitespaceRun, ' ') {
    nameFolded = _stripDiacritics(name);
    englishFolded = _stripDiacritics(english);
    vietnameseFolded = vietnamese == null ? null : _stripDiacritics(vietnamese!);
    aliases = [
      for (final alias in _countrySearchAliases[country.countryCode] ?? const [])
        (alias, _stripDiacritics(alias)),
    ];
  }

  final Country country;
  final String displayName, name, english, code, sortKey, label;
  final String? vietnamese;
  late final String nameFolded, englishFolded;
  late final String? vietnameseFolded;
  late final List<(String, String)> aliases;
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
      // `sizeOf`/`paddingOf`, not `MediaQuery.of`: the latter also depends on
      // the keyboard inset, and the search field autofocuses, so the whole
      // list would rebuild on every frame of the keyboard sliding in.
      final deviceHeight = MediaQuery.sizeOf(ctx).height;
      final statusBarHeight = MediaQuery.paddingOf(ctx).top;
      final height =
          countryListTheme?.bottomSheetHeight ??
          deviceHeight - (statusBarHeight + (kToolbarHeight / 1.5));
      final width = countryListTheme?.bottomSheetWidth;

      return Padding(
        padding:
            moveAlongWithKeyboard
                ? MediaQuery.viewInsetsOf(ctx)
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
  List<_SearchEntry> _index = const [];
  Map<String, _SearchEntry> _byCode = const {};
  List<_SearchEntry> _filteredList = [];
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
      final exclude = widget.exclude!.toSet();
      countries.removeWhere((country) => exclude.contains(country.countryCode));
    }

    if (widget.countryFilter != null) {
      final allowed = widget.countryFilter!.toSet();
      countries.removeWhere(
        (country) => !allowed.contains(country.countryCode),
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
    final localizations = CountryLocalizations.of(context);
    _index = [
      for (final country in _allCountries)
        _SearchEntry(country, _displayName(country, localizations)),
    ];
    _byCode = {for (final entry in _index) entry.country.countryCode: entry};
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

  bool _matchesCountry(_SearchEntry entry, String query, String queryNorm) {
    final cleanPhone = query.startsWith('+') ? query.substring(1) : query;
    if (entry.country.phoneCode.startsWith(cleanPhone)) return true;
    if (entry.code.startsWith(query)) return true;

    if (entry.name.contains(query)) return true;
    if (entry.nameFolded.contains(queryNorm)) return true;

    if (entry.english.contains(query)) return true;
    if (entry.englishFolded.contains(queryNorm)) return true;

    // Vietnamese name from CLDR (searchable in any locale, with or without accents)
    final viName = entry.vietnamese;
    if (viName != null) {
      if (viName.contains(query)) return true;
      if (entry.vietnameseFolded!.contains(queryNorm)) return true;
    }

    for (final (alias, aliasFolded) in entry.aliases) {
      if (alias.contains(query) || aliasFolded.contains(queryNorm)) {
        return true;
      }
    }

    return false;
  }

  void _filterList(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      final sorted = List<_SearchEntry>.of(_index)
        ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
      setState(() {
        _isSearching = false;
        _filteredList = sorted;
      });
      return;
    }

    final q = trimmed.toLowerCase();
    final qNorm = _stripDiacritics(q);

    final matches = _index.where((e) => _matchesCountry(e, q, qNorm)).toList();

    matches.sort((a, b) {
      // Exact ISO code match takes top priority (e.g. 'KR' or 'VN')
      final exactA = a.code == q;
      final exactB = b.code == q;
      if (exactA && !exactB) return -1;
      if (!exactA && exactB) return 1;

      // Prefix match on localized or English name
      final startsA =
          a.name.startsWith(q) ||
          a.nameFolded.startsWith(qNorm) ||
          a.english.startsWith(q);
      final startsB =
          b.name.startsWith(q) ||
          b.nameFolded.startsWith(qNorm) ||
          b.english.startsWith(q);
      if (startsA && !startsB) return -1;
      if (!startsA && startsB) return 1;

      return a.name.compareTo(b.name);
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
        Expanded(child: _buildList(textStyle)),
      ],
    );
  }

  /// Built lazily: only the rows on screen are constructed, so opening the
  /// sheet and every keystroke cost a screenful, not the whole world.
  Widget _buildList(TextStyle textStyle) {
    final favorites = _isSearching
        ? const <Country>[]
        : (_favoriteList ?? const <Country>[]);
    final header = favorites.isEmpty ? 0 : favorites.length + 1;
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: header + _filteredList.length,
      itemBuilder: (context, index) {
        if (index < favorites.length) {
          return _buildListRow(favorites[index], textStyle);
        }
        if (index < header) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(thickness: 1),
          );
        }
        return _buildListRow(_filteredList[index - header].country, textStyle);
      },
    );
  }

  Widget _buildListRow(Country country, TextStyle textStyle) {
    final label =
        _byCode[country.countryCode]?.label ??
        _displayName(
          country,
          CountryLocalizations.of(context),
        ).replaceAll(_whitespaceRun, ' ');

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
                child: Text(label, style: textStyle),
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
