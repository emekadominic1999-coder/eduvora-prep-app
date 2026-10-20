import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/news_item.dart';
import 'supabase_service.dart';

/// Reads the editorially managed news feed. There is no write path here by
/// design — see `supabase/schema.sql` for why.
class NewsRepository {
  const NewsRepository();

  Future<List<NewsItem>> fetchAll({String? category}) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    final PostgrestFilterBuilder<dynamic> builder =
        SupabaseService.client.from('news_items').select();
    final PostgrestFilterBuilder<dynamic> filtered =
        category == null ? builder : builder.eq('category', category);
    final List<dynamic> rows = await filtered
        .order('published_at', ascending: false)
        .limit(100);
    return rows
        .cast<Map<String, dynamic>>()
        .map(NewsItem.fromRow)
        .toList();
  }
}
