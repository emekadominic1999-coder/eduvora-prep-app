# Eduvora Prep

CBT past-question practice for Nigerian secondary school students — **JAMB UTME,
WAEC, NECO and Post-UTME** — built as a Flutter app for Android and the web.

Eduvora Prep is the secondary-school companion to Eduvora (which serves
university students). Same house style, different exam hall.

---

## What it does

**Sit a real past paper.** Pick an exam body, a subject and a year, then write
the paper under the clock. The question palette, the flagging, the free
movement between questions and the automatic submission when time expires all
behave the way the real CBT screen does.

**Two ways to practise.**

| Mode | Behaviour |
| --- | --- |
| Exam mode | Timed. Answers stay hidden until you submit. |
| Study mode | Untimed. The correct option and the explanation open as soon as you answer. |

**Every question carries an explanation.** Not just the letter of the right
answer, but why it is right — and, where it matters, why the attractive wrong
option is wrong.

**Know where you stand.** After each paper you get a score, a WAEC-style grade
band (A1–F9), a topic breakdown and a review screen that can be filtered to the
questions you got wrong or skipped. The Progress tab tracks accuracy over time,
ranks your subjects strongest to weakest and lists the topics that keep costing
you marks.

**Drills.** A *quick drill* pulls twenty questions across your own subjects. A
*mixed drill* pulls across every year of one subject. Saved questions can be
drilled as a paper of their own.

**Offline, with no account.** The whole question bank ships inside the app and
the profile, history, bookmarks and streak live on the device. No sign-up, no
server, no data cost after install.

---

## The question bank

Every bundled paper was cleared out deliberately — the bank now holds 14
subjects with an empty `"papers": []` array each, waiting to be repopulated
with verified real past questions rather than authored placeholders.

| | |
| --- | --- |
| Subjects | 14 |
| Papers | 0 (being rebuilt with real content) |
| Bodies supported | JAMB, WAEC, NECO |

Subjects: Use of English, Mathematics, Physics, Chemistry, Biology, Economics,
Government, Literature-in-English, Commerce, Financial Accounting, Christian
Religious Studies, Geography, Agricultural Science, Civic Education.

The bank lives in `assets/question_bank/<subject-id>.json`, one file per
subject, so a subject can be extended without touching any code:

```json
{
  "subject": "mathematics",
  "papers": [
    {
      "body": "JAMB",
      "year": 2024,
      "diet": "",
      "duration": 27,
      "questions": [
        {
          "id": "mth-j24-01",
          "topic": "Number bases",
          "instruction": "",
          "passage": "",
          "text": "Convert 101101₂ to a number in base ten.",
          "options": ["41", "43", "45", "47"],
          "answer": 2,
          "explanation": "101101₂ = 32 + 8 + 4 + 1 = 45."
        }
      ]
    }
  ]
}
```

`answer` is the zero-based index into `options`. `instruction` and `passage` are
optional — `passage` renders a comprehension extract above the stem, which is
what the English papers use.

Adding a subject means adding `assets/question_bank/<id>.json` and one entry in
`lib/core/data/subjects.dart`. A subject with no asset shows as "coming soon"
rather than breaking.

`test/question_bank_test.dart` guards the bank: unique ids, in-range answers, no
repeated options, an explanation on every question. Run it before committing new
content.

---

## Running it

```bash
flutter pub get
flutter run -d chrome
```

For Android:

```bash
flutter build apk --release
```

Tests and static analysis:

```bash
flutter test
flutter analyze
```

---

## How the code is laid out

```
lib/
  core/
    data/        subject catalogue, JAMB rules, exam-guide content
    models/      Question, PastPaper, ExamConfig, AttemptRecord, StudentProfile
    services/    QuestionBank — loads and indexes the JSON assets
    state/       AppState (ChangeNotifier) + AppScope, persisted to prefs
    theme/       palette, spacing, typography — shared with Eduvora
    widgets/     AppCard, SectionHeader, Pill, MeterRow, EmptyState
  features/
    onboarding/  three-step setup: name, exam body, subjects
    home/        dashboard, countdown, quick actions, exam guide
    practice/    browse by body, then subject, then year
    exam/        the CBT screen and its setup sheet
    result/      score sheet and question-by-question review
    performance/ accuracy over time, subject ranking, weak topics
    bookmarks/   saved questions and the drill built from them
    profile/     name, class, target exam, exam date, subjects
```

State is a single `ChangeNotifier` exposed through an `InheritedNotifier`
(`AppScope`) — no state-management package, no dependency injection framework.
Persistence is `shared_preferences`. The only other runtime dependency is
`intl`, for date formatting.

---

## Marking rules

There is no negative marking, matching JAMB: a skipped question and a wrong one
both score zero. Grades follow the WAEC/NECO bands — A1 at 75%, credit at 50%,
F9 below 40% — so the score on screen means the same thing it will mean on the
result slip.
