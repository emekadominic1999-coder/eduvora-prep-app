import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/forum.dart';
import 'supabase_service.dart';

/// Reads and writes the forum. Every student can read every question and
/// answer; only the author may edit or delete their own post (enforced by
/// RLS, not just by this layer).
class ForumRepository {
  const ForumRepository();

  Future<List<ForumQuestion>> fetchQuestions({ForumCategory? category}) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    final PostgrestFilterBuilder<dynamic> builder = SupabaseService.client
        .from('forum_questions_feed')
        .select();
    final PostgrestFilterBuilder<dynamic> filtered = category == null
        ? builder
        : builder.eq('category', category.name);
    final List<dynamic> rows =
        await filtered.order('created_at', ascending: false).limit(200);
    return rows
        .cast<Map<String, dynamic>>()
        .map(ForumQuestion.fromRow)
        .toList();
  }

  Future<List<ForumAnswer>> fetchAnswers(String questionId) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    final List<dynamic> rows = await SupabaseService.client
        .from('forum_answers_feed')
        .select()
        .eq('question_id', questionId)
        .order('created_at', ascending: true);
    return rows
        .cast<Map<String, dynamic>>()
        .map(ForumAnswer.fromRow)
        .toList();
  }

  Future<void> postQuestion({
    required String userId,
    required ForumCategory category,
    required String title,
    required String body,
  }) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    await SupabaseService.client.from('forum_questions').insert(<String, dynamic>{
      'user_id': userId,
      'category': category.name,
      'title': title.trim(),
      'body': body.trim(),
    });
  }

  Future<void> postAnswer({
    required String userId,
    required String questionId,
    required String body,
  }) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    await SupabaseService.client.from('forum_answers').insert(<String, dynamic>{
      'user_id': userId,
      'question_id': questionId,
      'body': body.trim(),
    });
  }
}
