import 'package:flutter/foundation.dart';

/// A marketplace classified — used books, calculators, tutoring, whatever a
/// student wants to buy or sell. There is no in-app payment: a buyer uses
/// [contactInfo] to reach the seller directly, same as myschool.ng's own
/// marketplace.
@immutable
class Listing {
  const Listing({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priceNaira,
    required this.category,
    required this.location,
    required this.contactInfo,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.sellerName = '',
  });

  factory Listing.fromRow(Map<String, dynamic> row) {
    return Listing(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      priceNaira: (row['price_naira'] as num?)?.toDouble() ?? 0,
      category: row['category'] as String? ?? 'other',
      location: row['location'] as String? ?? '',
      contactInfo: row['contact_info'] as String? ?? '',
      status: row['status'] as String? ?? 'active',
      createdAt: DateTime.parse(row['created_at'] as String),
      imageUrl: row['image_url'] as String?,
      sellerName: row['seller_name'] as String? ?? '',
    );
  }

  final String id;
  final String userId;
  final String title;
  final String description;
  final double priceNaira;
  final String category;
  final String location;
  final String contactInfo;
  final String status;
  final DateTime createdAt;
  final String? imageUrl;
  final String sellerName;

  bool get isSold => status == 'sold';
}

const List<String> listingCategories = <String>[
  'books',
  'electronics',
  'tutoring',
  'uniform',
  'other',
];
