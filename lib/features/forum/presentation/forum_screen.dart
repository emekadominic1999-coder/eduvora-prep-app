import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/forum.dart';
import '../../../core/services/forum_repository.dart';
import '../../../core/state/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'forum_question_screen.dart';

/// Q&A split into school-based questions (admissions, fees, porter) and
/// academic questions (subject help), matching myschool.ng's own split.
class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen>
    with SingleTickerProviderStateMixin {
  final ForumRepository _repo = const ForumRepository();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late Future<List<ForumQuestion>> _school;
  late Future<List<ForumQuestion>> _academic;

  @override
  void initState() {
    super.initState();
    // FutureBuilder requires the future to be created in initState (or
    // earlier), never lazily during build — see its own documentation.
    // TabBarView only mounts the page you are looking at (plus a small
    // cache margin), so the "Academic" tab's FutureBuilder may not exist
    // yet to subscribe to `_academic` by the time it settles. `.ignore()`
    // marks it handled regardless, without affecting the separate
    // subscription FutureBuilder makes once that page does mount.
    _school = _repo.fetchQuestions(category: ForumCategory.school)..ignore();
    _academic =
        _repo.fetchQuestions(category: ForumCategory.academic)..ignore();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _school = _repo.fetchQuestions(category: ForumCategory.school);
      _academic = _repo.fetchQuestions(category: ForumCategory.academic);
    });
  }

  Future<void> _ask() async {
    final ForumCategory category =
        _tabs.index == 0 ? ForumCategory.school : ForumCategory.academic;
    final bool? posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _AskSheet(category: category),
    );
    if (posted == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const <Widget>[
            Tab(text: 'School-based'),
            Tab(text: 'Academic'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ask,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ask'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: <Widget>[
          _QuestionList(future: _school, onReload: _reload),
          _QuestionList(future: _academic, onReload: _reload),
        ],
      ),
    );
  }
}

class _QuestionList extends StatelessWidget {
  const _QuestionList({required this.future, required this.onReload});

  final Future<List<ForumQuestion>> future;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: FutureBuilder<List<ForumQuestion>>(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<List<ForumQuestion>> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load this',
              message: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: onReload,
            );
          }
          final List<ForumQuestion> items = snap.data ?? const <ForumQuestion>[];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_rounded,
              title: 'No questions yet',
              message: 'Be the first to ask something here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              96,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int i) {
              final ForumQuestion q = items[i];
              return AppCard(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ForumQuestionScreen(question: q),
                    ),
                  );
                  onReload();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(q.title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      q.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        Text(
                          q.authorName,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: AppColours.textFaint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${q.answerCount}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          DateFormat('d MMM').format(q.createdAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AskSheet extends StatefulWidget {
  const _AskSheet({required this.category});

  final ForumCategory category;

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _posting = true);
    try {
      await const ForumRepository().postQuestion(
        userId: sessionController.profile!.id,
        category: widget.category,
        title: _title.text,
        body: _body.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SessionController.describeError(error))),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Ask a ${widget.category.label.toLowerCase()} question',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _title,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _body,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Add more detail (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _posting ? null : _post,
                child: _posting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text('Post question'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
