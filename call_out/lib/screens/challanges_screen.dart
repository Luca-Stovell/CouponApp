// lib/screens/challanges_screen.dart
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'create_coupon_screen.dart';

class ChallengesScreen extends StatefulWidget {
  final AppState state;
  const ChallengesScreen({super.key, required this.state});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final List<_Challenge> _items = [];

  // ---- Form controllers for the add/edit sheet ----
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _friend;
  DateTime? _due;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _openCreateSheet() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _friend = (widget.state.friends.isNotEmpty)
        ? widget.state.friends.first
        : null;
    _due = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // StatefulBuilder so the sheet itself rebuilds when the friend or due
      // date changes (the screen's setState doesn't redraw a modal sheet).
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'New Challenge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _friend,
                    items: widget.state.friends
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setSheetState(() => _friend = v),
                    decoration: const InputDecoration(
                      labelText: 'Friend',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Pick a friend' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., 5k run together',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Add a title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'What do they need to do?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: Text(
                            _due == null
                                ? 'Add due date (optional)'
                                : 'Due: ${_fmtDate(_due!)}',
                          ),
                          onPressed: () async {
                            final today = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _due ?? today,
                              firstDate: today.subtract(
                                const Duration(days: 1),
                              ),
                              lastDate: today.add(
                                const Duration(days: 365 * 2),
                              ),
                            );
                            if (picked != null) {
                              setSheetState(() => _due = picked);
                            }
                          },
                        ),
                      ),
                      if (_due != null)
                        IconButton(
                          tooltip: 'Clear date',
                          onPressed: () => setSheetState(() => _due = null),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.flag),
                    label: const Text('Create challenge'),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() {
                        _items.add(
                          _Challenge(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            friend: _friend!,
                            title: _titleCtrl.text.trim(),
                            description: _descCtrl.text.trim().isEmpty
                                ? null
                                : _descCtrl.text.trim(),
                            due: _due,
                          ),
                        );
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Challenge created')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  void _markComplete(_Challenge c) async {
    setState(() {
      final idx = _items.indexWhere((x) => x.id == c.id);
      if (idx != -1) {
        _items[idx] = c.copyWith(completed: true, completedAt: DateTime.now());
      }
    });

    // Offer to issue a coupon now by jumping to CreateCouponScreen
    if (mounted) {
      final action = await showDialog<_CompleteAction>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Challenge completed!'),
          content: Text('Issue a coupon to ${c.friend} now as a reward?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, _CompleteAction.dismiss),
              child: const Text('Later'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.card_giftcard),
              onPressed: () => Navigator.pop(ctx, _CompleteAction.issueNow),
              label: const Text('Issue coupon'), // <-- was `child:`
            ),
          ],
        ),
      );

      if (action == _CompleteAction.issueNow) {
        // Navigate to your existing create-coupon flow.
        // (You can enhance CreateCouponScreen to accept optional prefill args if you like.)
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateCouponScreen(state: widget.state),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.state.friends;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        actions: [
          IconButton(
            tooltip: 'New challenge',
            icon: const Icon(Icons.add),
            onPressed: friends.isEmpty
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Add a friend first to create a challenge.',
                        ),
                      ),
                    );
                  }
                : _openCreateSheet,
          ),
        ],
      ),
      body: _items.isEmpty
          ? const _EmptyChallenges()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = _items[i];
                return Dismissible(
                  key: ValueKey(c.id),
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete),
                  ),
                  secondaryBackground: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete),
                  ),
                  onDismissed: (_) {
                    setState(() => _items.removeAt(i));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Challenge deleted')),
                    );
                  },
                  child: _ChallengeCard(
                    challenge: c,
                    onComplete: c.completed ? null : () => _markComplete(c),
                  ),
                );
              },
            ),
      floatingActionButton: friends.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add),
              label: const Text('New challenge'),
            ),
    );
  }
}

// ===== Helpers & widgets =====

enum _CompleteAction { dismiss, issueNow }

class _EmptyChallenges extends StatelessWidget {
  const _EmptyChallenges();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No challenges yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a challenge for a friend. When they complete it, you can reward them with a coupon.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final _Challenge challenge;
  final VoidCallback? onComplete;

  const _ChallengeCard({required this.challenge, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        !challenge.completed &&
        challenge.due != null &&
        DateTime.now().isAfter(
          DateTime(
            challenge.due!.year,
            challenge.due!.month,
            challenge.due!.day,
            23,
            59,
            59,
          ),
        );

    return ListTile(
      leading: CircleAvatar(
        child: Text(challenge.friend.isNotEmpty ? challenge.friend[0] : '?'),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              challenge.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: challenge.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (challenge.completed)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('For: ${challenge.friend}'),
          if (challenge.description != null &&
              challenge.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(challenge.description!),
            ),
          if (challenge.due != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                'Due: ${_fmtDate(challenge.due!)}${isOverdue ? "  •  overdue" : ""}',
                style: TextStyle(
                  color: isOverdue ? Theme.of(context).colorScheme.error : null,
                  fontWeight: isOverdue ? FontWeight.w600 : null,
                ),
              ),
            ),
          if (challenge.completedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text('Completed: ${_fmtDate(challenge.completedAt!)}'),
            ),
        ],
      ),
      trailing: onComplete == null
          ? null
          : FilledButton.tonalIcon(
              icon: const Icon(Icons.flag),
              onPressed: onComplete,
              label: const Text('Complete'),
            ),
    );
  }
}

String _fmtDate(DateTime d) {
  // Format as dd Mon yyyy (lightweight, no intl dependency)
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}

class _Challenge {
  final String id;
  final String friend;
  final String title;
  final String? description;
  final DateTime? due;
  final bool completed;
  final DateTime? completedAt;

  _Challenge({
    required this.id,
    required this.friend,
    required this.title,
    this.description,
    this.due,
    this.completed = false,
    this.completedAt,
  });

  _Challenge copyWith({
    String? id,
    String? friend,
    String? title,
    String? description,
    DateTime? due,
    bool? completed,
    DateTime? completedAt,
  }) {
    return _Challenge(
      id: id ?? this.id,
      friend: friend ?? this.friend,
      title: title ?? this.title,
      description: description ?? this.description,
      due: due ?? this.due,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
