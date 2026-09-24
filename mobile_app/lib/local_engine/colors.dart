/// Port of `calculation-engine/src/colors.js`.
///
/// Two personalised colours for a local civil day. Editorial symbolism, not a
/// validated prediction and not an automatic Yong Shen / Xi Shen: the engine
/// does not claim a favourable element for a person, only a pairing derived
/// from the day's own stem and that day's module signals. A module with no
/// coverage drops out of its weighted signal rather than being invented.
library;

import 'core/core.dart';
import 'core/numbers.dart';

class PaletteShade {
  const PaletteShade(this.key, this.name, this.hex);

  final String key;
  final String name;
  final String hex;
}

/// Ten Heavenly Stems, two shades each. The rule this replaced folded the ten
/// stems into five colours, so the day stem advancing by one each day repeated
/// the colour every second day.
const List<List<PaletteShade>> palette = <List<PaletteShade>>[
  [
    PaletteShade('cedar', 'Cedar', '#4EAE83'),
    PaletteShade('jade', 'Jade', '#56C6A5'),
  ],
  [
    PaletteShade('sage', 'Sage', '#9BBF8A'),
    PaletteShade('mint', 'Mint', '#AADBB2'),
  ],
  [
    PaletteShade('ember', 'Ember', '#D97566'),
    PaletteShade('solar_coral', 'Solar Coral', '#E88862'),
  ],
  [
    PaletteShade('rose', 'Rose', '#C9758F'),
    PaletteShade('blossom', 'Blossom', '#DC8DA0'),
  ],
  [
    PaletteShade('ochre', 'Ochre', '#C59E61'),
    PaletteShade('amber', 'Amber', '#D4AA68'),
  ],
  [
    PaletteShade('sand', 'Sand', '#D8BF92'),
    PaletteShade('clay', 'Clay', '#C9A77A'),
  ],
  [
    PaletteShade('silver', 'Silver', '#AAB9CB'),
    PaletteShade('steel', 'Steel', '#95AAC1'),
  ],
  [
    PaletteShade('pearl', 'Pearl', '#E8DED0'),
    PaletteShade('champagne', 'Champagne', '#E4D5B5'),
  ],
  [
    PaletteShade('ocean_blue', 'Ocean Blue', '#66A9D2'),
    PaletteShade('azure', 'Azure', '#4F9CCB'),
  ],
  [
    PaletteShade('indigo', 'Indigo', '#899AD5'),
    PaletteShade('mist_blue', 'Mist Blue', '#9FBCE1'),
  ],
];

/// The Five Element each Heavenly Stem belongs to, in stem order.
const List<String> stemElements = <String>[
  'wood',
  'wood',
  'fire',
  'fire',
  'earth',
  'earth',
  'metal',
  'metal',
  'water',
  'water',
];

/// The stems of each element: the yang stem first, then the yin stem.
const Map<String, List<int>> elementStems = <String, List<int>>{
  'wood': [0, 1],
  'fire': [2, 3],
  'earth': [4, 5],
  'metal': [6, 7],
  'water': [8, 9],
};

/// The generating cycle (相生). The supporting colour comes from the family the
/// lead's element generates, so the two are always different families.
const Map<String, String> generates = <String, String>{
  'wood': 'fire',
  'fire': 'earth',
  'earth': 'metal',
  'metal': 'water',
  'water': 'wood',
};

/// Module weights for the lead shade: the full-day general reading.
const Map<String, double> leadWeights = <String, double>{
  'B': .30,
  'Z': .30,
  'W': .20,
  'N': .20,
};

/// Module weights for the supporting family. Excludes Ba Zi on purpose, so the
/// second colour is not a restatement of the first.
const Map<String, double> supportWeights = <String, double>{
  'Z': .40,
  'W': .30,
  'N': .30,
};

typedef ColorSegment = ({double duration, Map<String, Evidence> modules});

/// Duration-weighted average of each module over the whole local day, so the
/// result cannot depend on when the app was opened.
Map<String, Evidence> dailyModules(List<ColorSegment> segments) {
  if (segments.isEmpty) throw const EngineFailure('INVALID_SEGMENTS');
  var seconds = 0.0;
  for (final segment in segments) {
    if (!segment.duration.isFinite || segment.duration <= 0) {
      throw const EngineFailure('INVALID_SEGMENTS');
    }
    seconds += segment.duration;
  }
  if (seconds == 0) throw const EngineFailure('INVALID_SEGMENTS');

  final a = <String, double>{},
      c = <String, double>{},
      coverage = <String, double>{};
  for (final segment in segments) {
    segment.modules.forEach((name, module) {
      a[name] = (a[name] ?? 0) + segment.duration * module.a;
      c[name] = (c[name] ?? 0) + segment.duration * module.c;
      coverage[name] =
          (coverage[name] ?? 0) + segment.duration * module.coverage;
    });
  }
  return <String, Evidence>{
    for (final name in a.keys)
      name: Evidence(
        a[name]! / seconds,
        c[name]! / seconds,
        coverage[name]! / seconds,
      ),
  };
}

/// One signal in [-1, 1] from the named modules' action axis, each weighted by
/// its own data coverage and then normalised by the weight actually present.
double colorSignal(Map<String, Evidence> modules, Map<String, double> weights) {
  var sum = 0.0, total = 0.0;
  weights.forEach((name, weight) {
    final module = modules[name];
    if (module == null || module.coverage == 0) return;
    final applied = weight * module.coverage;
    sum += applied * module.a;
    total += applied;
  });
  return total == 0 ? 0 : clampUnit(sum / total);
}

/// The day's two colours, as the JSON the contract carries.
///
/// - **Lead**: the local civil day's stem fixes the family; its two shades are
///   separated by the sign of the full-day [leadWeights] signal.
/// - **Supporting**: the family the lead's element generates. Which of that
///   family's two stems is chosen by the sign of the [supportWeights] signal
///   (yang stem when non-negative, yin otherwise), and the shade within it by
///   the parity of the numerology personal day.
Map<String, Object?> dailyColors(
  List<ColorSegment> segments,
  int dayStem,
  int personalDay,
) {
  if (dayStem < 0 || dayStem > 9) throw const EngineFailure('INVALID_DAY_STEM');
  final modules = dailyModules(segments);

  final leadElement = stemElements[dayStem];
  final lead = palette[dayStem][colorSignal(modules, leadWeights) >= 0 ? 1 : 0];

  final supportElement = generates[leadElement]!;
  final supportStem =
      elementStems[supportElement]![colorSignal(modules, supportWeights) >= 0
          ? 0
          : 1];
  final supporting = palette[supportStem][personalDay.abs() % 2];

  return <String, Object?>{
    'lead': <String, Object?>{
      'key': lead.key,
      'name': lead.name,
      'hex': lead.hex,
      'element': leadElement,
      'stem': dayStem,
    },
    'supporting': <String, Object?>{
      'key': supporting.key,
      'name': supporting.name,
      'hex': supporting.hex,
      'element': supportElement,
      'stem': supportStem,
    },
    'meaning': 'symbolic_colour_pairing_not_yong_shen',
  };
}
