# Birth-time control copy — Claude draft, pending Codex review

**These four keys were written by Claude, not by Codex.** They are the only
strings in the app that did not come from the editorial pack. They are here,
in the same table format as the rest of the handoff, so Codex can review or
replace them in place and Claude will regenerate the ARB files from this file
unchanged.

They were needed by a product change: the birth-time control is now
`I know my birth time`, **on** by default, instead of the inverted
`Birth time unknown` switch. Nothing is prefilled — a reader who leaves the
control on must pick a real time before continuing, and a reader who does not
know theirs turns it off and the reading takes the unknown-birth-hour path.

Each one is a close parallel of a sentence the pack already approves, rather
than free composition, so the register should match:

| Draft key | Modelled on |
|---|---|
| `selectBirthTime` | `selectBirthDate` |
| `birthTimeRequired` | `birthDateRequired` |
| `knowBirthTime` | `birthTimeUnknown` (the switch it replaces) |
| `knowBirthTimeDetail` | `birthTimeUnknownDetail` (its opposite state) |

`birthTimeUnknownDetail` is unchanged and still used, as the subtitle shown
when the control is **off**.

| Key | en | vi | ja | es |
|---|---|---|---|---|
| knowBirthTime | I know my birth time | Tôi biết giờ sinh của mình | 出生時刻がわかる | Sé mi hora de nacimiento |
| knowBirthTimeDetail | An exact time sharpens the hour-based cycles. | Giờ sinh chính xác giúp các chu kỳ theo giờ rõ nét hơn. | 正確な時刻ほど、時辰の周期がはっきりします。 | Una hora exacta afina los ciclos basados en la hora. |
| selectBirthTime | Select your time of birth | Chọn giờ sinh | 出生時刻を選択 | Selecciona tu hora de nacimiento |
| birthTimeRequired | Select your time of birth to continue, or turn this off if you do not know it. | Hãy chọn giờ sinh để tiếp tục, hoặc tắt mục này nếu bạn không biết. | 続けるには出生時刻を選択してください。わからない場合はこの設定をオフにしてください。 | Selecciona tu hora de nacimiento para continuar, o desactiva esta opción si no la sabes. |

| Key | th | hi-IN | zh-Hans-CN |
|---|---|---|---|
| knowBirthTime | ฉันทราบเวลาเกิดของฉัน | मुझे अपना जन्म समय पता है | 我知道自己的出生时间 |
| knowBirthTimeDetail | เวลาที่แม่นยำช่วยให้วงจรตามชั่วโมงชัดเจนขึ้น | सटीक समय से घंटे पर आधारित चक्र और स्पष्ट होते हैं। | 越准确的时间，时辰周期越清晰。 |
| selectBirthTime | เลือกเวลาเกิดของคุณ | अपना जन्म समय चुनें | 选择出生时间 |
| birthTimeRequired | โปรดเลือกเวลาเกิดก่อนดำเนินต่อ หรือปิดตัวเลือกนี้หากคุณไม่ทราบ | आगे बढ़ने के लिए जन्म समय चुनें, या यदि आपको पता नहीं है तो इसे बंद कर दें। | 请选择出生时间后继续；如果不清楚，请关闭此选项。 |

## What Codex should check

- That `knowBirthTime` reads as a statement the reader is agreeing with, not
  as a question or an instruction.
- That `knowBirthTimeDetail` does not promise a better or more accurate
  reading — it says the hour-based cycles are sharper, which is a statement
  about the calculation's inputs, not about the outcome.
- `時辰` in the Japanese and Chinese detail lines: the pack's own note says to
  keep `时辰` for birth-hour patterns rather than for a clock time, which is
  what it means here.
- Whether `birthTimeRequired` should name the control the reader has to turn
  off. Claude kept it indirect ("this") rather than repeating the switch
  label, which would need re-agreement between the two strings in every
  language.
