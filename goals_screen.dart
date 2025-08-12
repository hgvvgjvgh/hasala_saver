import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/goal_repository.dart';
import '../model/goal.dart';

final goalRepoProvider = Provider((ref) => GoalRepository());
final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(goalRepoProvider);
  return repo.getGoals();
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('أهداف الادخار'),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(child: Text('ابدأ بإضافة أول هدف ادخار'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) => GoalTile(goal: goals[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: goals.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('حدث خطأ: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddGoalDialog(),
        ).then((_) => ref.refresh(goalsProvider)),
        label: const Text('إضافة هدف'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class GoalTile extends ConsumerWidget {
  final Goal goal;
  const GoalTile({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(goalRepoProvider);
    return FutureBuilder<double>(
      future: repo.getSavedForGoal(goal.id ?? -1),
      builder: (context, snapshot) {
        final saved = snapshot.data ?? 0;
        final p = goal.progress(saved);
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(goal.name, style: Theme.of(context).textTheme.titleMedium)),
                    Text('${(p*100).toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: p),
                const SizedBox(height: 8),
                Text('${saved.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)}'),
                if (goal.dueDate != null)
                  Text('الاستحقاق: ${DateFormat('yyyy-MM-dd').format(goal.dueDate!)}',
                      style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _addTransaction(context, goal.id!, true).then((_) => (context as Element).markNeedsBuild()),
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('إيداع'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _addTransaction(context, goal.id!, false).then((_) => (context as Element).markNeedsBuild()),
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('سحب'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        await ref.read(goalRepoProvider).deleteGoal(goal.id!);
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الهدف')));
                        // ignore: use_build_context_synchronously
                        (context as Element).markNeedsBuild();
                      },
                      icon: const Icon(Icons.delete_outline),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class AddGoalDialog extends ConsumerStatefulWidget {
  const AddGoalDialog({super.key});

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _due;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('هدف جديد'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الهدف')),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'المبلغ المستهدف'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_due == null ? 'بدون تاريخ' : DateFormat('yyyy-MM-dd').format(_due!)),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 10),
                    initialDate: now,
                    locale: const Locale('ar'),
                  );
                  if (picked != null) setState(() => _due = picked);
                },
                child: const Text('اختر التاريخ'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () async {
            final name = _name.text.trim();
            final amount = double.tryParse(_amount.text.trim()) ?? 0;
            if (name.isEmpty || amount <= 0) return;
            final goal = Goal(name: name, targetAmount: amount, dueDate: _due, createdAt: DateTime.now());
            await ref.read(goalRepoProvider).addGoal(goal);
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
          child: const Text('حفظ'),
        )
      ],
    );
  }
}

Future<void> _addTransaction(BuildContext context, int goalId, bool deposit) async {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(deposit ? 'إيداع' : 'سحب'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountCtrl,
            decoration: const InputDecoration(labelText: 'المبلغ'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () async {
            final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
            if (amount <= 0) return;
            final db = await AppDb.database;
            await db.insert('transactions', {
              'goal_id': goalId,
              'type': deposit ? 'deposit' : 'withdraw',
              'amount': amount,
              'note': noteCtrl.text.trim(),
              'date': DateTime.now().toIso8601String(),
            });
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
          child: const Text('تأكيد'),
        )
      ],
    ),
  );
}

import '../data/app_db.dart';