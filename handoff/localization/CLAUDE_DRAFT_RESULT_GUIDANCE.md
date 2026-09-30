# Result guidance copy — Claude draft, pending Codex review

**Every string in `mobile_app/lib/data/action_guidance.dart` was rewritten by
Claude, in all seven languages.** It replaces copy that Codex had written. This
page says why, so the decision can be reversed or reworked rather than
discovered.

## What was wrong with the copy it replaces

The guidance was selected by **life-area category × polarity × tenure tier ×
daily variant**. The decision mode was not consulted at all, so a KEEP / LET GO
reading and a YES / NO reading in the same category produced the same three
sentences — the one thing the reader had actually chosen was the one thing the
text ignored.

Writing per category also meant writing about money and about relationships
without knowing anything about either. The English `love` set included:

> *"A decisive call to release. Letting go is your path back to peace."*
> *"Honor your self-worth and walk away from situations that drain you."*
> *"Looking back or hoping someone will suddenly change who they are."*

That tells a reader to end a relationship, and invents a person who is
mistreating them. The app knows a birth date, a category chip and a percentage.

## What replaced it

Selection is now **decision mode × which side the reading named**, plus one
shared balanced reflection. Fifteen entries per language, three sentences each:

- `headline` — what the reading leaned toward, in that mode's own terms.
- `shouldDo` — something to turn over. Never an instruction about the world.
- `avoid` — a way of misreading this that is worth naming.

Category is gone from the copy entirely. It still shapes the score and is still
shown on screen; it is just no longer something the app writes advice about.

Rules the copy follows, enforced by `test/action_guidance_test.dart`:

- No line names money, work, a partner or any third person.
- No line says to start, end, buy, sell, join or leave anything.
- No two modes share a headline, in any language.
- The two sides of a pair never say the same thing.
- LEFT / RIGHT keeps its physical-navigation warning on both sides.

## What was dropped, and was not asked to be

Two features of the old selection went with it, because both chose between
texts that no longer exist:

1. **The journey-tenure progression** (days 1–7 gentle, 8–30 rhythm, 31+
   direct). `resolveGuidanceTier` and the profile-creation lookup on the result
   screen are gone with it.
2. **The daily rotation between three variants.** The guidance is now stable
   for a given mode and side. Arguably that is more honest — the percentages
   already move daily, and rotating the interpretation underneath them suggests
   the interpretation changed when only the wording did — but it is a change.

Restoring either means writing 3× or 9× the copy, which is why it was not done
here rather than a judgement that it should not exist.

## Register

English is the source; the other six are transcreations, not literal
translations. They aim at the same voice the rest of the app uses: plain,
second person, no exclamation, no promises. A native reader should check that
none of them has drifted into instruction — the line between *"ask what you
would take with you"* and *"decide what to take"* is the whole point, and it is
easy to lose in translation.

One phrasing worth a second look: the `keep_let_go:second` avoid line
(`"Reading a symbolic lean as a reason to decide something for someone else"`)
is carrying real safety weight. It should stay pointed in every language.
