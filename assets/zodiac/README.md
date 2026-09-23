# AstraCue: Cosmic Decisions zodiac avatars — v1

Twelve circular avatars for the app's **Celestial Observatory** visual system.

## Canonical order

1. Aries
2. Taurus
3. Gemini
4. Cancer
5. Leo
6. Virgo
7. Libra
8. Scorpio
9. Sagittarius
10. Capricorn
11. Aquarius
12. Pisces

Each exported PNG is a 362×362 RGBA cell with a transparent outer background.
Use the full circular medallion; do not crop the gold rim. Recommended UI display size is
64–112 logical pixels, with no additional circular clipping mask.

Flutter should resolve the engine-provided Western sun-sign key through `manifest.json`.
Do not duplicate date-cutoff logic inside the UI.

## Art direction

- Deep navy enamel: `#070B16` / `#0D1424`
- Muted antique gold: `#D8B66A`
- Violet accent: `#786FE8`
- Ocean-blue accent: `#2477C9`
- Soft ivory highlight: `#F4F7FC`
- Calm, modern, mysterious and trustworthy; no harsh red or casino styling.

## Source and regeneration

`zodiac_avatar_master_v1.png` is the generated 4×3 master sheet. Re-slice it with:

```sh
python tools/slice_zodiac_sheet.py assets/zodiac/zodiac_avatar_master_v1.png assets/zodiac
```

Generation mode: built-in ImageGen. The prompt requested a strict 4×3 canonical zodiac grid,
identical circular medallions, transparent gutters, no text and consistent line weight.
The complete generation prompt is preserved in `generation_prompt.txt`.
