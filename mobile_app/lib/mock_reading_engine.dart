import 'models.dart';

ReadingResult createMockReading(DecisionMode mode, TimePeriod period) {
  final preset = switch (mode) {
    DecisionMode.yesNo => ('YES', 64, 'NO'),
    DecisionMode.actWait => ('WAIT', 61, 'ACT'),
    DecisionMode.advanceRetreat => ('ADVANCE', 58, 'RETREAT'),
    DecisionMode.stayGo => ('GO', 58, 'STAY'),
    DecisionMode.keepLetGo => ('LET GO', 63, 'KEEP'),
    DecisionMode.forwardBackward => ('FORWARD', 57, 'BACKWARD'),
    DecisionMode.leftRight => ('RIGHT', 54, 'LEFT'),
  };

  final difference = (preset.$2 - 50).abs();
  final alignment = switch (difference) {
    0 => 'Evenly balanced',
    <= 7 => 'Gentle lean',
    <= 17 => 'Clear lean',
    _ => 'Strong lean',
  };

  return ReadingResult(
    mode: mode,
    period: period,
    winner: preset.$1,
    winnerPercent: preset.$2,
    counterpart: preset.$3,
    counterpartPercent: 100 - preset.$2,
    alignment: alignment,
    windows: period == TimePeriod.now
        ? const []
        : const [
            LuckyWindow('7:00 PM – 9:00 PM', 72),
            LuckyWindow('9:00 PM – 11:00 PM', 66),
          ],
  );
}
