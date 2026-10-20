import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/listing.dart';
import '../../../core/services/marketplace_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'create_listing_screen.dart';
import 'listing_detail_screen.dart';

final NumberFormat nairaFormat =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceRepository _repo = const MarketplaceRepository();
  late Future<List<Listing>> _future;
  String? _category;

  @override
  void initState() {
    super.initState();
    // FutureBuilder requires the future to be created in initState (or
    // earlier), never lazily during build — see its own documentation.
    _future = _repo.fetchActive()..ignore();
  }

  void _reload() {
    setState(() => _future = _repo.fetchActive(category: _category));
  }

  Future<void> _create() async {
    final bool? posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CreateListingScreen()),
    );
    if (posted == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sell'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _CategoryChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () {
                    _category = null;
                    _reload();
                  },
                ),
                ...listingCategories.map((String c) => Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _CategoryChip(
                        label: c,
                        selected: _category == c,
                        onTap: () {
                          _category = c;
                          _reload();
                        },
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<Listing>>(
                future: _future,
                builder:
                    (BuildContext context, AsyncSnapshot<List<Listing>> snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load this',
                      message: 'Check your connection and try again.',
                      actionLabel: 'Retry',
                      onAction: _reload,
                    );
                  }
                  final List<Listing> items = snap.data ?? const <Listing>[];
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.storefront_rounded,
                      title: 'Nothing for sale yet',
                      message: 'Be the first to list something here.',
                      actionLabel: 'Sell something',
                      onAction: _create,
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.screenPadding,
                      AppSpacing.screenPadding,
                      96,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Listing listing = items[i];
                      return _ListingCard(
                        listing: listing,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ListingDetailScreen(listing: listing),
                            ),
                          );
                          _reload();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label[0].toUpperCase() + label.substring(1)),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.1,
            child: ClipRRect(
              borderRadius: AppRadii.sm,
              child: listing.imageUrl == null
                  ? Container(
                      color: AppColours.surfaceMuted,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColours.textFaint,
                        size: 32,
                      ),
                    )
                  : Image.network(listing.imageUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            nairaFormat.format(listing.priceNaira),
            style: text.titleSmall?.copyWith(color: AppColours.primary),
          ),
          Text(
            listing.title,
            style: text.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (listing.location.isNotEmpty)
            Text(
              listing.location,
              style: text.labelSmall?.copyWith(color: AppColours.textFaint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
