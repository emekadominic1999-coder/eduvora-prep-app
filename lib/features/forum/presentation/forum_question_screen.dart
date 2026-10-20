import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/forum.dart';
import '../../../core/services/forum_repository.dart';
import '../../../core/state/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

class ForumQuestionScreen extends StatefulWidget {
  const ForumQuestionScreen({super.key, required this.question});

  final ForumQuestion question;

  @override
  State<ForumQuestionScreen> createState() => _ForumQuestionScreenState();
}

class _ForumQuestionScreenState extends State<ForumQuestionScreen> {
  final ForumRepository _repo = const ForumRepository();
  final TextEditingController _reply = TextEditingController();
  late Future<List<ForumAnswer>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // FutureBuilder requires the future to be created in initState (or
    // earlier), never lazily during build — see its own documentation.
    _future = _repo.fetchAnswers(widget.question.id)..ignore();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_reply.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await _repo.postAnswer(
        userId: sessionController.profile!.id,
        questionId: widget.question.id,
        body: _reply.text,
      );
      _reply.clear();
      setState(() => _future = _repo.fetchAnswers(widget.question.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SessionController.describeError(error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Question')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: <Widget>[
                Pill(widget.question.category.label, colour: AppColours.primary),
                const SizedBox(height: AppSpacing.md),
                Text(widget.question.title, style: text.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${widget.question.authorName} · '
                  '${DateFormat('d MMM y').format(widget.question.createdAt)}',
                  style: text.bodySmall,
                ),
                if (widget.question.body.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Text(widget.question.body, style: text.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                FutureBuilder<List<ForumAnswer>>(
                  future: _future,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<ForumAnswer>> snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final List<ForumAnswer> answers =
                        snap.data ?? const <ForumAnswer>[];
                    if (answers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          'No answers yet — be the first to help.',
                          style: text.bodySmall,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${answers.length} '
                          '${answers.length == 1 ? 'answer' : 'answers'}',
                          style: text.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...answers.map((ForumAnswer a) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: AppCard(
                                colour: AppColours.surfaceMuted,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(a.body, style: text.bodyMedium),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      '${a.authorName} · '
                                      '${DateFormat('d MMM').format(a.createdAt)}',
                                      style: text.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _reply,
                      decoration: const InputDecoration(
                        hintText: 'Write an answer…',
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
