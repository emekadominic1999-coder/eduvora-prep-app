import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/listing.dart';
import 'supabase_service.dart';

class MarketplaceRepository {
  const MarketplaceRepository();

  static const Uuid _uuid = Uuid();

  Future<List<Listing>> fetchActive({String? category}) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    final PostgrestFilterBuilder<dynamic> builder = SupabaseService.client
        .from('marketplace_listings_feed')
        .select();
    PostgrestFilterBuilder<dynamic> filtered = builder.eq('status', 'active');
    if (category != null) {
      filtered = filtered.eq('category', category);
    }
    final List<dynamic> rows =
        await filtered.order('created_at', ascending: false).limit(200);
    return rows.cast<Map<String, dynamic>>().map(Listing.fromRow).toList();
  }

  Future<List<Listing>> fetchMine(String userId) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    final List<dynamic> rows = await SupabaseService.client
        .from('marketplace_listings_feed')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>().map(Listing.fromRow).toList();
  }

  /// Uploads [bytes] to the public marketplace-images bucket and returns a
  /// public URL, or null if the upload failed.
  Future<String?> uploadImage(String userId, Uint8List bytes) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    if (bytes.lengthInBytes > AppConfig.maxImageBytes) return null;
    final String path = '$userId/${_uuid.v4()}.jpg';
    try {
      await SupabaseService.client.storage
          .from(AppConfig.marketplaceImagesBucket)
          .uploadBinary(path, bytes);
      return SupabaseService.client.storage
          .from(AppConfig.marketplaceImagesBucket)
          .getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> create({
    required String userId,
    required String title,
    required String description,
    required double priceNaira,
    required String category,
    required String location,
    required String contactInfo,
    String? imageUrl,
  }) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    await SupabaseService.client.from('marketplace_listings').insert(
      <String, dynamic>{
        'user_id': userId,
        'title': title.trim(),
        'description': description.trim(),
        'price_naira': priceNaira,
        'category': category,
        'location': location.trim(),
        'contact_info': contactInfo.trim(),
        'image_url': imageUrl,
      },
    );
  }

  Future<void> markSold(String listingId) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    await SupabaseService.client
        .from('marketplace_listings')
        .update(<String, dynamic>{'status': 'sold'})
        .eq('id', listingId);
  }

  Future<void> delete(String listingId) async {
    // Defers past the first synchronous frame so a thrown error (e.g.
    // Supabase not yet initialised) becomes a normal Future error that
    // FutureBuilder can show, rather than crashing the widget build.
    await Future<void>.value();
    await SupabaseService.client
        .from('marketplace_listings')
        .delete()
        .eq('id', listingId);
  }
}
