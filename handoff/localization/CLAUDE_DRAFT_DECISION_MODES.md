# ADVANCE / RETREAT copy — Claude draft, pending Codex review

**The ADVANCE / RETREAT words and one loading line were written by Claude, not
by Codex.** Everything else on this page is approved pack copy that only moved
to a different key. Codex can review or replace the drafts in place.

## What was wrong

The app was showing the **COMMIT / WITHDRAW** words under the
**ADVANCE / RETREAT** mode, in all seven languages. `choiceAdvance` held
`COMMIT`, `choiceRetreat` held `WITHDRAW`, and `loadingModeAdvanceRetreat`
said *"Balancing commitment against withdrawal"*. Meanwhile the seventh mode
was FORWARD / BACKWARD, which the engine no longer offers.

Ruleset v9.1 makes the seven modes:

1. YES / NO
2. ACT / WAIT
3. **ADVANCE / RETREAT** — today's push measured against the last three days
4. STAY / GO
5. KEEP / LET GO
6. **COMMIT / WITHDRAW** — replaces FORWARD / BACKWARD, driven by a seven-day
   durability horizon
7. LEFT / RIGHT

## What moved, unchanged

The approved COMMIT / WITHDRAW copy was not rewritten. It moved verbatim to
keys of its own:

| Was | Is now |
|---|---|
| `choiceAdvance` | `choiceCommit` |
| `choiceRetreat` | `choiceWithdraw` |
| `loadingModeAdvanceRetreat` | `loadingModeCommitWithdraw` |

`choiceForward`, `choiceBackward` and `loadingModeForwardBackward` are **kept**
and still translated. A reading saved before v9.1 is never relabelled
COMMIT / WITHDRAW — its percentage was never calculated for that question — so
history still has to render the FORWARD / BACKWARD pair.

## What Claude drafted

`choiceAdvance` and `choiceRetreat` needed words of their own, and
`loadingModeAdvanceRetreat` needed a line about momentum rather than
commitment. The sense is tactical: press forward now, or pull back now — not
"commit to this" and not a physical direction.

| Locale | `choiceAdvance` | `choiceRetreat` | `loadingModeAdvanceRetreat` |
|---|---|---|---|
| en | ADVANCE | RETREAT | Measuring today's push against the last few days |
| vi | TIẾN LÊN | LÙI LẠI | Đối chiếu đà của hôm nay với vài ngày trước |
| es | AVANZAR | REPLEGARSE | Comparando el impulso de hoy con los últimos días |
| ja | 進む | 退く | 今日の勢いを直近の数日と比べています |
| th | เดินหน้า | ถอยกลับ | กำลังเทียบแรงผลักของวันนี้กับไม่กี่วันก่อน |
| hi | आगे बढ़ें | पीछे लौटें | आज की गति को पिछले कुछ दिनों से तौल रहे हैं |
| zh-Hans | 进取 | 退守 | 正在将今日的势头与前几日相比 |

Notes on the choices, for whoever reviews them:

- **es** — `REPLEGARSE` rather than `RETIRARSE`, because `RETIRARSE` is
  already the approved word for WITHDRAW and the two modes must not read the
  same.
- **hi** — `पीछे लौटें` rather than `पीछे हटें`, for the same reason:
  `पीछे हटें` is the approved WITHDRAW word.
- **zh** — `进取 / 退守` is the tactical advance/retreat pair, distinct from
  the approved `投入 / 抽离` for COMMIT / WITHDRAW.
- **vi** — `TIẾN LÊN / LÙI LẠI` is the natural advance/retreat pair, and it is
  also what the retired FORWARD / BACKWARD mode says in Vietnamese. **A
  Vietnamese reader with pre-v9.1 history will see the same two words on an
  old FORWARD / BACKWARD reading and on a new ADVANCE / RETREAT one.** The
  percentages and dates differ, but the labels do not. If that is not
  acceptable, the legacy `choiceForward` / `choiceBackward` pair is the one to
  change, since nothing new is ever calculated for it.

## `navigationDetail`

The safety line named FORWARD / BACKWARD, which is no longer a mode. It now
names ADVANCE / RETREAT, using each language's new words above. The sentence
structure and the rest of its wording are untouched:

> LEFT / RIGHT and ADVANCE / RETREAT are symbolic choices only. Never use them
> for traffic, driving, route-finding, or physical safety.

No new claim was added, and no country-specific or legal wording was
introduced.
