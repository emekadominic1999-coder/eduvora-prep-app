import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/news_item.dart';
import '../../../core/services/news_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

const List<String> _kCategories = <String>[
  'All',
  'General News',
  'JAMB News',
  'O\'Level News',
  'Admission News',
];

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsRepository _repo = const NewsRepository();
  late Future<List<NewsItem>> _future;
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    // FutureBuilder requires the future to be created in initState (or
    // earlier), never lazily during build — see its own documentation.
    _future = _repo.fetchAll()..ignore();
  }

  void _reload() {
    setState(() {
      _future = _repo.fetchAll(category: _category == 'All' ? null : _category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam News')),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: _kCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int i) {
                final String cat = _kCategories[i];
                return ChoiceChip(
                  label: Text(cat),
                  selected: _category == cat,
                  onSelected: (_) {
                    _category = cat;
                    _reload();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<NewsItem>>(
                future: _future,
                builder: (BuildContext context, AsyncSnapshot<List<NewsItem>> snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return _ErrorState(onRetry: _reload);
                  }
                  final List<NewsItem> items = snap.data ?? const <NewsItem>[];
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.newspaper_rounded,
                      title: 'No stories yet',
                      message: 'Check back soon for exam news and updates.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) =>
                        _NewsCard(item: items[i]),
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

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _NewsDetailScreen(item: item)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Pill(item.category, colour: item.categoryColour),
              const Spacer(),
              Text(
                DateFormat('d MMM').format(item.publishedAt),
                style: text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.title, style: text.titleSmall),
          const SizedBox(height: 4),
          Text(
            item.summary,
            style: text.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NewsDetailScreen extends StatelessWidget {
  const _NewsDetailScreen({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: <Widget>[
          Pill(item.category, colour: item.categoryColour),
          const SizedBox(height: AppSpacing.md),
          Text(item.title, style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${DateFormat('d MMMM y').format(item.publishedAt)}'
            '${item.sourceLabel.isNotEmpty ? ' · ${item.sourceLabel}' : ''}',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(item.body, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Could not load this',
      message: 'Check your connection and try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}
