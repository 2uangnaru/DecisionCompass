import 'data/models/models.dart' as engine;
import 'models.dart';

/// Explicit, exhaustive translation between the UI enums in `models.dart` and
/// the engine wire enums in `data/models/`.
///
/// Both libraries deliberately use the same names, so this is the only file
/// that imports them together. The switches have no `default` clause: adding a
/// mode or period breaks compilation here instead of silently falling through
/// to YES/NO.
engine.DecisionMode toEngineMode(DecisionMode mode) => switch (mode) {
  DecisionMode.yesNo => engine.DecisionMode.yesNo,
  DecisionMode.actWait => engine.DecisionMode.actWait,
  DecisionMode.advanceRetreat => engine.DecisionMode.advanceRetreat,
  DecisionMode.stayGo => engine.DecisionMode.stayGo,
  DecisionMode.keepLetGo => engine.DecisionMode.keepLetGo,
  DecisionMode.forwardBackward => engine.DecisionMode.forwardBackward,
  DecisionMode.leftRight => engine.DecisionMode.leftRight,
};

DecisionMode fromEngineMode(engine.DecisionMode mode) => switch (mode) {
  engine.DecisionMode.yesNo => DecisionMode.yesNo,
  engine.DecisionMode.actWait => DecisionMode.actWait,
  engine.DecisionMode.advanceRetreat => DecisionMode.advanceRetreat,
  engine.DecisionMode.stayGo => DecisionMode.stayGo,
  engine.DecisionMode.keepLetGo => DecisionMode.keepLetGo,
  engine.DecisionMode.forwardBackward => DecisionMode.forwardBackward,
  engine.DecisionMode.leftRight => DecisionMode.leftRight,
};

engine.TimePeriod toEnginePeriod(TimePeriod period) => switch (period) {
  TimePeriod.now => engine.TimePeriod.now,
  TimePeriod.morning => engine.TimePeriod.morning,
  TimePeriod.midday => engine.TimePeriod.midday,
  TimePeriod.afternoon => engine.TimePeriod.afternoon,
  TimePeriod.evening => engine.TimePeriod.evening,
};

TimePeriod fromEnginePeriod(engine.TimePeriod period) => switch (period) {
  engine.TimePeriod.now => TimePeriod.now,
  engine.TimePeriod.morning => TimePeriod.morning,
  engine.TimePeriod.midday => TimePeriod.midday,
  engine.TimePeriod.afternoon => TimePeriod.afternoon,
  engine.TimePeriod.evening => TimePeriod.evening,
};
