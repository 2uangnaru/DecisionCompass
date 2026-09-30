import 'json_types.dart';

/// Decision mode sent to, and echoed back by, the calculation engine.
///
/// Wire values match `Mode` in `calculation-engine/src/index.d.ts` exactly.
/// Each mode mixes its own set of v9.1 signals — never treat [commitWithdraw]
/// or [leftRight] as aliases of [yesNo].
enum DecisionMode {
  yesNo('yes_no'),
  actWait('act_wait'),
  advanceRetreat('advance_retreat'),
  stayGo('stay_go'),
  keepLetGo('keep_let_go'),
  commitWithdraw('commit_withdraw'),
  leftRight('left_right'),

  /// Retired with ruleset v9.1, kept so saved readings still parse.
  ///
  /// COMMIT/WITHDRAW asks a different question and is scored from a different
  /// signal, so an old FORWARD/BACKWARD reading is never relabelled as one:
  /// its percentage was never calculated for that question. The engine
  /// refuses to compute new readings in this mode.
  forwardBackward('forward_backward', legacy: true);

  const DecisionMode(this.wireValue, {this.legacy = false});

  /// Exact JSON string value expected by the engine contract.
  final String wireValue;

  /// Whether this mode exists only to read history back.
  final bool legacy;

  /// The modes a reader may still choose, in no particular display order.
  static List<DecisionMode> get selectable =>
      values.where((mode) => !mode.legacy).toList(growable: false);

  static DecisionMode fromWire(
    String value, {
    String context = 'DecisionMode',
  }) {
    for (final mode in DecisionMode.values) {
      if (mode.wireValue == value) return mode;
    }
    throw ReadingDtoException('Unknown $context value "$value"');
  }

  String toJson() => wireValue;
}
