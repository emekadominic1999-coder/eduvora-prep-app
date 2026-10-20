import '../models/video_lesson.dart';
import 'supabase_service.dart';

class VideoLessonRepository {
  const VideoLessonRepository();

  Future<List<VideoLesson>> fetchAll() async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    final List<dynamic> rows = await SupabaseService.client
        .from('video_lessons')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    return rows
        .cast<Map<String, dynamic>>()
        .map(VideoLesson.fromRow)
        .toList();
  }
}
