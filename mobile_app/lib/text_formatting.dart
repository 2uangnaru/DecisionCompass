/// Turns an engine wire value like `ocean_blue` into `Ocean Blue` for display.
///
/// Shared by every place that shows a raw engine string (e.g. `DailyBrief`'s
/// `colorInspiration`) directly to the user.
String titleCaseWords(String snakeCase) => snakeCase
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
