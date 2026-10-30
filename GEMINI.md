# AstraCue Project Guidelines & Engine Invariants

## 1. Cosmic Context & Action Guidance Formatting Invariants

### A. Two-Paragraph Cosmic Context Card (`_CosmicContextCard`)
* Format headlines as **exactly two paragraphs** separated by `\n\n` (Cách 1).
* **Paragraph 1 (Transit & Natal Anchor):**
  - Combines real calendar/transit calculations with the user's natal chart.
  - East Asian locales (`vi`, `zh`, `ja`, `ko`): Time of day + Can Chi day & 12 Day Officers (`ngày Quý Hợi (Trực Trừ)`) + category focus (`xét trong công việc`) + Natal Five Elements (`bản mệnh Kim / Thổ / Mộc / Hỏa / Thủy`) + energetic resonance state.
  - Western & South Asian locales (`en`, `es`, `th`, `hi`): Time of day + Lunar phase / astrological transit (`under the waxing moon`) + Natal Zodiac sign (`your Taurus / Scorpio clarity`) + energetic resonance state.
* **Paragraph 2 (Cosmic Mechanism):**
  - Philosophical rationale for the decision mode & lean (`ACT`, `WAIT`, `ADVANCE`, `RETREAT`, `BALANCED`).
  - Rotates across 3 distinct variants (`v0`, `v1`, `v2`) derived from `readingKey`.
* **Ethical Copy Standards:** 0 fatalistic predictions, 0 raw numbers or percentages in headlines, 0 forbidden absolute words.

### B. Action Guidance Card (`_ActionGuidanceCard`)
* Dedicated dictionary across 8 languages (`vi`, `en`, `es`, `ja`, `ko`, `th`, `hi`, `zh`).
* **Consider / Should Do (`Nên`):** Must start with localized time prefix (`Đầu ngày: `, `Giữa ngày: `, `Buổi chiều: `, `Cuối ngày: `) followed by domain-specific positive action.
* **Watch for / Avoid (`Tránh`):** Must describe behavioral pitfalls and conclude with a localized time-of-day cadence reminder in parentheses (e.g., `(tránh để sự chậm trễ đầu ngày kéo theo cả ngày).`).
* **Hindi Typography:** Use Hindi danda `।` exclusively; never append Western `.`.

## 2. Calculation Engine & Parsing Invariants

* **Date Parsing:** In `cosmic_time_anchor.dart`, always sanitize `birthDateStr` to 10 characters `YYYY-MM-DD` (`birthDateStr.split('T').first`) before passing to `civilCalendar`. Never pass full ISO-8601 strings with `T...`.
* **Profile Differentiation:** Ensure distinct profiles evaluate to distinct `readingKey` hashes, distinct natal anchors, and distinct guidance variants.
* **Time & Category Differentiation:** The same profile across different categories (`career`, `money`, `love`, `study`, `friends`, `general`) or periods (`morning`, `afternoon`, `evening`, `now`) must yield tailored, non-colliding copy.

## 3. Verification & Code Quality Gates

* Before completing any changes to guidance, run:
  ```powershell
  flutter test test/paragraph_integrity_test.dart test/action_guidance_test.dart test/two_profiles_comparison_test.dart test/time_and_category_variation_test.dart
  flutter analyze
  ```
* All test permutations must pass 100% with 0 analyzer issues.

## 4. Building a Test APK

* Every debug APK built for the owner to test must enable demo Plus billing:
  ```powershell
  $env:JAVA_HOME='C:\Users\ADMIN\develop\jdk-17'
  $env:ANDROID_HOME='C:\Users\ADMIN\AppData\Local\Android\sdk'
  C:\Users\ADMIN\develop\flutter\bin\flutter.bat build apk --debug --dart-define=PLUS_DEMO_BILLING=true
  ```
* Without the flag the APK uses real Play billing with no verifier: the Plus Buy button is blocked and does nothing visible, so the owner cannot test VIP.
* The flag only works in debug builds; release builds ignore it. Never drop it to "fix" a build.
