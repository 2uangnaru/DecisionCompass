/// The approved Daily Energy insights, eight per tone.
///
/// The engine decides the tone; nothing here does. These pools only choose
/// which of that tone's eight sentences to show, so an insight can never
/// contradict the level the calculation produced.
///
/// Each pool opens with the sentence that shipped before the rotation existed,
/// kept verbatim. `focused` and `flowing` describe which signal is leading —
/// direction and flexibility — not a higher reading than `radiant`; the index
/// is an internal symbolic value, never a probability or a prediction.
///
/// There is no pool for `unavailable`: a day the engine could not read has no
/// insight, and the app offers none.
const dailyEnergyMessagePools = <String, List<String>>{
  'quiet': [
    'Today’s symbolic energy turns inward, making space for quiet reflection.',
    'Today’s cosmic rhythm turns inward; stillness may reveal what noise has '
        'been hiding.',
    'The sky’s symbolic tone is hushed today; give your thoughts room to '
        'settle.',
    'A quieter current runs through this day, inviting you to notice rather '
        'than rush.',
    'Today’s signs suggest reflection; a pause can still be part of moving '
        'forward.',
    'When the day feels subdued, your inner compass may speak more clearly.',
    'The energy of this day leaves space to listen before naming an answer.',
    'Not every signal arrives loudly; today’s may be easier to notice when you '
        'slow down.',
  ],
  'soft': [
    'Today’s symbolic energy moves gently, with room for care and small steps.',
    'A gentle cosmic current moves through today; small steps may feel more '
        'natural than big leaps.',
    'Today’s energy leaves room for care; approach your choice without '
        'pressing for certainty.',
    'The day’s softer rhythm may help you begin with what feels manageable.',
    'A gentler approach can still be strong today; notice where you need ease, '
        'not pressure.',
    'Today’s signs suggest a light touch: enough movement to begin, without '
        'forcing the pace.',
    'The current is subtle today; simple, thoughtful actions may carry more '
        'meaning.',
    'Even a small opening can matter; today’s gentle pattern leaves space to '
        'explore it.',
  ],
  'steady': [
    'Today’s symbolic energy keeps an even, grounded rhythm.',
    'Today’s symbolic energy holds an even rhythm; trust the pace you can '
        'sustain.',
    'The cosmic pattern feels grounded, offering room to think and move '
        'deliberately.',
    'A steady current runs beneath this day; attention may serve you better '
        'than urgency.',
    'Today’s signs point toward balance, without asking you to stand still.',
    'There is strength in consistency; notice which next step still makes '
        'sense after a pause.',
    'The day carries a measured energy, giving your choice room to take shape.',
    'A calm rhythm can be its own guide; progress need not be dramatic today.',
  ],
  'lively': [
    'A playful spark stirs today’s symbolic energy, bringing curiosity and '
        'motion.',
    'A curious spark stirs today’s symbolic energy; a fresh angle may be worth '
        'exploring.',
    'The day feels more animated; notice what catches your attention without '
        'rushing toward it.',
    'Today’s cosmic rhythm invites discovery, with space to stay discerning.',
    'A playful current moves through this day; possibilities may appear in '
        'unexpected places.',
    'Curiosity may be a useful signal today; notice where it points before you '
        'commit.',
    'There is motion in today’s signs; you can explore without committing too '
        'quickly.',
    'The energy feels lively; let it widen your options before narrowing them.',
  ],
  'bright': [
    'Today’s symbolic energy shines with momentum and room for expression.',
    'Today’s symbolic energy brings more light to what you want to express.',
    'A brighter cosmic current may help you see which possibility deserves '
        'attention.',
    'The signs of this day feel open; your next step may become easier to '
        'name.',
    'Today carries momentum for expression; share what matters when the moment '
        'feels right.',
    'An opening in today’s rhythm may encourage clarity without demanding '
        'haste.',
    'The day’s energy feels outward-facing; notice what you’re ready to bring '
        'forward.',
    'A touch of brightness can shift perspective; today’s patterns invite you '
        'to look ahead.',
  ],
  'radiant': [
    'Today’s symbolic energy reaches its fullest glow: open and expansive.',
    'Today’s symbolic energy opens wide, inviting you to see more than one '
        'possible path.',
    'A radiant current runs through this day; let possibility expand without '
        'losing your center.',
    'The cosmic pattern feels especially open; make room for what inspires '
        'you.',
    'A fuller glow colors today’s energy, bringing your possibilities into a '
        'wider view.',
    'Today’s signs carry an expansive tone; it may be easier to imagine what '
        'comes next.',
    'Let the day’s warmth widen your view while keeping the final choice in '
        'your hands.',
    'The sky’s symbolic rhythm feels generous; welcome possibilities with '
        'grounded judgment.',
  ],
  'focused': [
    'Today’s symbolic energy gathers around a clear direction; the action '
        'signal takes the lead.',
    'Today’s action signal comes into focus; notice the one step that feels '
        'intentional.',
    'The symbolic current leans toward doing, but you can choose the pace.',
    'A sense of direction runs through today; attend to what you can actually '
        'influence.',
    'When options compete, today’s signs invite you to center on one practical '
        'move.',
    'Today’s signs gather around one intention; give it your attention without '
        'rushing.',
    'Action has a stronger symbolic pull today; keep your reasons clear before '
        'moving.',
    'This is a day for intention, not intensity; let your chosen direction '
        'take shape.',
  ],
  'flowing': [
    'Today’s symbolic energy moves with the tide; the change signal takes the '
        'lead.',
    'Today’s change signal comes forward; allow your plans a little room to '
        'bend.',
    'A shifting cosmic current runs through the day; adaptability may reveal '
        'another path.',
    'The energy of change is more noticeable; stay open to what a new angle '
        'shows you.',
    'Today’s signs speak of movement between possibilities, not a fixed '
        'destination.',
    'When circumstances shift, a flexible response may serve you better than a '
        'rigid plan.',
    'A flowing rhythm moves through this day; notice what can evolve without '
        'forcing an answer.',
    'The symbolic current leans toward transition; you can move with it at '
        'your own pace.',
  ],
};

/// How many insights each tone carries.
const dailyEnergyPoolSize = 8;

/// Whether [level] has insights at all. `unavailable`, and any level a future
/// engine adds before this build knows it, return false so the ⓘ is withheld
/// rather than showing an apology.
bool hasDailyEnergyInsight(String? level) =>
    level != null && dailyEnergyMessagePools.containsKey(level);
