import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/scholarship.dart';
import '../../../core/services/scholarship_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

class ScholarshipsScreen extends StatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  final ScholarshipRepository _repo = const ScholarshipRepository();
  late Future<List<Scholarship>> _future;

  @override
  void initState() {
    super.initState();
    // FutureBuilder requires the future to be created in initState (or
    // earlier), never lazily during build — see its own documentation.
    _future = _repo.fetchAll()..ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scholarships')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _repo.fetchAll()),
        child: FutureBuilder<List<Scholarship>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<Scholarship>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load this',
                message: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => setState(() => _future = _repo.fetchAll()),
              );
            }
            final List<Scholarship> items = snap.data ?? const <Scholarship>[];
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.school_rounded,
                title: 'No scholarships listed yet',
                message: 'Check back soon for new opportunities.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int i) =>
                  _ScholarshipCard(item: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ScholarshipCard extends StatelessWidget {
  const _ScholarshipCard({required this.item});

  final Scholarship item;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (item.degreeLevel.isNotEmpty)
                Pill(item.degreeLevel, colour: AppColours.primary),
              if (item.country.isNotEmpty) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Pill(item.country, colour: AppColours.textMuted),
              ],
              const Spacer(),
              if (item.isExpired)
                const Pill('Closed', colour: AppColours.danger)
              else if (item.deadline != null)
                Pill(
                  'Due ${DateFormat('d MMM').format(item.deadline!)}',
                  colour: AppColours.accent,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.title, style: text.titleSmall),
          const SizedBox(height: 4),
          Text(item.description, style: text.bodySmall),
          if (item.link != null && item.link!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(item.link!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('View details'),
            ),
          ],
        ],
      ),
    );
  }
}
