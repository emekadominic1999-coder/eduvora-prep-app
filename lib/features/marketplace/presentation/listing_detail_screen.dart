import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/listing.dart';
import '../../../core/services/marketplace_repository.dart';
import '../../../core/state/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'marketplace_screen.dart' show nairaFormat;

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final Listing listing;

  bool get _isMine => sessionController.profile?.id == listing.userId;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing'),
        actions: <Widget>[
          if (_isMine)
            PopupMenuButton<String>(
              onSelected: (String action) async {
                final MarketplaceRepository repo = const MarketplaceRepository();
                if (action == 'sold') {
                  await repo.markSold(listing.id);
                } else if (action == 'delete') {
                  await repo.delete(listing.id);
                }
                if (context.mounted) Navigator.pop(context, true);
              },
              itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'sold',
                  child: Text('Mark as sold'),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete listing'),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.3,
            child: ClipRRect(
              borderRadius: AppRadii.lg,
              child: listing.imageUrl == null
                  ? Container(
                      color: AppColours.surfaceMuted,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColours.textFaint,
                        size: 48,
                      ),
                    )
                  : Image.network(listing.imageUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Pill(listing.category, colour: AppColours.primary),
              if (listing.isSold) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                const Pill('Sold', colour: AppColours.danger),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            nairaFormat.format(listing.priceNaira),
            style: text.headlineSmall?.copyWith(color: AppColours.primary),
          ),
          const SizedBox(height: 4),
          Text(listing.title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${listing.sellerName} · ${listing.location} · '
            '${DateFormat('d MMM y').format(listing.createdAt)}',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(listing.description, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          if (!_isMine && !listing.isSold)
            FilledButton.icon(
              onPressed: () => _contact(context),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Contact seller'),
            ),
        ],
      ),
    );
  }

  Future<void> _contact(BuildContext context) async {
    final String info = listing.contactInfo.trim();
    final Uri? uri = _toUri(info);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Contact the seller'),
        content: SelectableText(info.isEmpty ? 'No contact details given.' : info),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Uri? _toUri(String info) {
    final String trimmed = info.trim();
    if (trimmed.contains('@') && !trimmed.contains(' ')) {
      return Uri(scheme: 'mailto', path: trimmed);
    }
    final String digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length >= 10 && digits == trimmed.replaceAll(' ', '')) {
      return Uri(scheme: 'tel', path: digits);
    }
    return null;
  }
}
