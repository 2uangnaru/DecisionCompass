import 'json_types.dart';

/// Decision mode sent to, and echoed back by, the calculation engine.
///
/// Wire values match `Mode` in `calculation-engine/src/index.d.ts` exactly.
/// Each mode is an independent symbolic projection (see
/// `Decision_Compass_UX_UI_Spec` / engine README) — never treat
/// [forwardBackward] or [leftRight] as aliases of [yesNo].
enum DecisionMode {
  yesNo('yes_no'),
  actWait('act_wait'),
  advanceRetreat('advance_retreat'),
  stayGo('stay_go'),
  keepLetGo('keep_let_go'),
  forwardBackward('forward_backward'),
  leftRight('left_right');

  const DecisionMode(this.wireValue);

  /// Exact JSON string value expected by the engine contract.
  final String wireValue;

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
