import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_dashboard_provider.dart';

class CreateHabitBottomSheet extends ConsumerStatefulWidget {
  const CreateHabitBottomSheet({super.key});

  @override
  ConsumerState<CreateHabitBottomSheet> createState() =>
      _CreateHabitBottomSheetState();
}

class _CreateHabitBottomSheetState
    extends ConsumerState<CreateHabitBottomSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text;
    if (title.trim().isNotEmpty) {
      // Execute the action through the Notifier (Option A)
      ref.read(habitDashboardProvider.notifier).addHabit(title);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Shifts bottom sheet up when soft keyboard appears
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Habit',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Read 20 pages',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Save Habit'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}