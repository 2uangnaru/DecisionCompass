# Editorial review — 2026-09-28

Content ownership: Codex. The user does **not** need to approve translations line by line. This review approves the included copy as the **prototype integration draft** for Claude's code work; it is not a claim of professional native-language or jurisdictional legal certification.

## Checks completed

- Seven locale rotation JSON files parse successfully. Each contains exactly 30 Home descriptions and 64 Daily Energy insights, with matching 94-key sets, no empty values and no exact duplicate sentence within a locale.
- Core-screen matrices have the same 70 keys in all seven locales. Safety-sheet matrices have the same 23 keys in both language groups. Loading narration has the same 13 keys in both language groups.
- The seven decision pairs are translated by stable choice ID, not by the English winner text returned by the engine. Eight Daily Energy levels and 20 color keys are translated by stable IDs. The engine values, formulas, numerical percentages, HEX colors and saved deck indices remain untranslated.
- `Everyday Money` was narrowed editorially to `Everyday Spending` in UI copy so the category does not invite investment/borrowing use. Its wire value remains `money`.
- The dynamic “Your luckiest times in {period}” pattern was replaced by four complete headings; the symbolic-score caveat stays immediately visible.
- The safety sheet's fixed Vietnam/US numbers and broad “at least 13” / “100% responsibility” claims were replaced by country-neutral prototype copy. No new emergency number or jurisdictional legal claim was invented.
- No strings or formatting instructions claim the percentages are probabilities or that the app commands the user's decision. Home descriptions and energy insights keep the user's agency.
- The welcome language selector is on-screen and user-initiated, not an automatic popup. English remains the first-launch default; language is saved before profile creation and is independent of current country, birthplace and timezone.

## Integration blockers Claude must report back

1. Some visible UI strings are not yet in the editorial pack: error/status variants, history/share text, zodiac names and some accessibility labels. Claude should extract them to a missing-key manifest and use English-only development fallback; do **not** silently release mixed-language screens or invent translations. Codex will fill the manifest without asking the user to review each line.
2. The app currently has no bundled font family. Claude must verify Han, Devanagari, Thai and Japanese glyphs, shaping and line height on Android devices and at larger text scale. No document can guarantee font rendering without that code/test pass.
3. The existing birth-country field remains separate from language. The product decision about removing it and replacing its time-zone evidence remains open; localization must not infer birthplace from language or location.
4. Store-release age/privacy/legal compliance and native-language copy QA are separate checks. The prototype integration draft is not that certification.

## Source of truth

- `CORE_COPY.md`, `CORE_COPY_VI.md`, `CORE_COPY_HI_ZH.md`
- `rotation_en.json`, `rotation_vi.json`, `rotation_ja.json`, `rotation_es.json`, `rotation_th.json`, `rotation_hi_IN.json`, `rotation_zh_Hans_CN.json`
- `SELECTOR_AND_TERMS.md`, `LUCKY_TIMES_HEADINGS.md`, `LOADING_COPY.md`, `SAFETY_COPY.md`
- `README.md` for implementation contract and ownership

No Flutter source, build or Git push is part of this editorial review.
