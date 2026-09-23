import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A short briefing shown in the "Exam guide" strip. These are evergreen
/// explanations of how the exams work and how to prepare, not news items —
/// nothing here goes stale between diets.
@immutable
class GuideItem {
  const GuideItem({
    required this.title,
    required this.summary,
    required this.body,
    required this.icon,
    required this.colour,
    required this.category,
  });

  final String title;
  final String summary;
  final String body;
  final IconData icon;
  final Color colour;
  final String category;
}

class Guides {
  const Guides._();

  static const List<GuideItem> all = <GuideItem>[
    GuideItem(
      category: 'JAMB',
      title: 'How the UTME is scored',
      summary: 'Four subjects, 180 questions, 400 marks.',
      icon: Icons.calculate_rounded,
      colour: AppColours.primary,
      body:
          'The UTME is sat on computer in one two-hour session. You answer '
          'four subjects: Use of English, which carries 60 questions, and '
          'three others carrying 40 questions each — 180 questions in all.\n\n'
          'Each subject is scored out of 100, giving a total of 400. There is '
          'no negative marking, so an unanswered question and a wrong one are '
          'worth the same: nothing. Never leave a question blank. If time is '
          'running out, eliminate what you can and choose.\n\n'
          'Work out your pace before you start. Two hours across 180 questions '
          'is about 40 seconds a question. English comprehension will take '
          'longer, so bank time on the questions you know on sight.',
    ),
    GuideItem(
      category: 'Technique',
      title: 'Working the CBT screen',
      summary: 'Flag, skip and come back — do not get stuck.',
      icon: Icons.touch_app_rounded,
      colour: AppColours.accent,
      body:
          'In the hall you can move freely between questions. Use that.\n\n'
          'First pass: answer everything you are sure of and flag anything '
          'that needs thought. Second pass: return to the flagged questions '
          'with the clock in view. Third pass: fill in every remaining blank, '
          'guessing where you must.\n\n'
          'Students lose more marks to one stubborn question eating eight '
          'minutes than to genuine ignorance. The question palette in this '
          'app behaves the same way as the real one, so practise using it.',
    ),
    GuideItem(
      category: 'WAEC & NECO',
      title: 'Objective papers and the grading bands',
      summary: 'A1 to F9, and what a credit really means.',
      icon: Icons.workspace_premium_rounded,
      colour: Color(0xFF047857),
      body:
          'WAEC and NECO report results in nine bands: A1, B2, B3 are '
          'distinction to very good; C4, C5, C6 are credit; D7 and E8 are a '
          'pass; F9 is a fail.\n\n'
          'Most universities and polytechnics ask for five credits at C6 or '
          'better, including English Language and Mathematics, in not more '
          'than two sittings. A "pass" at D7 or E8 does not count towards '
          'that requirement, which surprises many candidates each year.\n\n'
          'The objective paper is where marks are cheapest to earn. Past '
          'questions repeat in substance year after year, which is exactly '
          'what this app drills.',
    ),
    GuideItem(
      category: 'Technique',
      title: 'Why past questions work',
      summary: 'Examiners reuse the same ground every year.',
      icon: Icons.repeat_rounded,
      colour: Color(0xFF7C3AED),
      body:
          'Syllabuses change slowly, and examiners test the same core ideas '
          'in slightly different clothes. A student who has worked ten years '
          'of past questions in a subject has usually met every topic the '
          'next paper can ask about.\n\n'
          'The trick is not to memorise answers. Memorising "B" for question '
          '14 of 2019 is worthless when the options are reshuffled. Work each '
          'question until you can say why the right option is right and why '
          'each other option is wrong. That is why every question in this app '
          'carries an explanation.\n\n'
          'Use Study mode when you are learning a topic and Exam mode when '
          'you are testing whether you have learnt it.',
    ),
    GuideItem(
      category: 'Preparation',
      title: 'Building a revision timetable',
      summary: 'Short daily sessions beat weekend marathons.',
      icon: Icons.event_note_rounded,
      colour: AppColours.info,
      body:
          'Spaced practice beats cramming, and the research on this is not '
          'close. Forty minutes a day for six days will leave more in your '
          'memory than four hours on a Saturday.\n\n'
          'A workable pattern: one subject a day on rotation, one timed paper '
          'a week per subject, and a review session every Sunday on the '
          'topics your progress screen shows as weakest.\n\n'
          'Track the weak topics rather than the total score. A score tells '
          'you where you stand; a topic breakdown tells you what to do next.',
    ),
    GuideItem(
      category: 'Exam day',
      title: 'What to take to the centre',
      summary: 'Slip, ID, and nothing that looks like a phone.',
      icon: Icons.badge_rounded,
      colour: AppColours.danger,
      body:
          'Take your examination slip and a valid means of identification. '
          'Arrive early enough to find your seat without rushing — centres '
          'are often far from home and transport is unpredictable.\n\n'
          'Phones, smart watches, calculators where they are not permitted, '
          'and written material of any kind will get you disqualified. Leave '
          'them with someone outside or at home.\n\n'
          'If your system freezes or the questions do not load, raise your '
          'hand and report it immediately rather than waiting. Time lost to a '
          'reported fault can usually be restored; time lost in silence '
          'cannot.',
    ),
  ];
}
