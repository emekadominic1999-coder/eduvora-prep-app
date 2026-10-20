import '../models/scholarship.dart';
import 'supabase_service.dart';

class ScholarshipRepository {
  const ScholarshipRepository();

  Future<List<Scholarship>> fetchAll() async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    final List<dynamic> rows = await SupabaseService.client
        .from('scholarships')
        .select()
        .order('deadline', ascending: true, nullsFirst: false)
        .limit(100);
    return rows
        .cast<Map<String, dynamic>>()
        .map(Scholarship.fromRow)
        .toList();
  }
}
