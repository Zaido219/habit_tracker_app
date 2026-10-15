import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/habit_dashboard_provider.dart';
import '../../domain/models/habit.dart';

class CreateHabitBottomSheet extends ConsumerStatefulWidget {
  final Habit? habitToEdit; // pass a habit object if editing
  final VoidCallback? onClose;
  final bool useKeyboardInset;

  const CreateHabitBottomSheet({
    super.key,
    this.habitToEdit,
    this.onClose,
    this.useKeyboardInset = true, //modal sheet defualt
  });

  @override
  ConsumerState<CreateHabitBottomSheet> createState() =>
      _CreateHabitBottomSheetState();
}

class _CreateHabitBottomSheetState
    extends ConsumerState<CreateHabitBottomSheet> {
  // Palette to pick from — swap/extend these however you like
  static const _colorOptions = <Color>[
    Color(0xFF6750A4), // deep purple
    Color(0xFFD85A30), // coral
    Color(0xFF639922), // green
    Color(0xFF378ADD), // blue
    Color(0xFFD4537E), // pink
    Color(0xFFBA7517), // amber
  ];

  Color _selectedColor = _colorOptions.first;
  TimeOfDay? _reminderTime;
  final _controller = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.habitToEdit != null) {
      _controller.text = widget.habitToEdit!.title;
      _notesController.text = widget.habitToEdit!.habitNotes;
    }
  }

  Future<void> _pickReminderDate() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  String _colorToHex(Color color) {
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  void _submit() {
    final title = _controller.text.trim();
    final notes = _notesController.text.trim();
    final time = _reminderTime;
    final reminderTime = time == null
        ? null
        : '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';

    if (title.isNotEmpty) {
      final notifier = ref.read(habitDashboardProvider.notifier);
      final selectedColorHex = _colorToHex(_selectedColor);

      if (widget.habitToEdit != null) {
        // 1. UPDATE LOGIC: Create an updated model instance using copyWith
        final updatedHabit = widget.habitToEdit!.copyWith(
          title: title,
          colorHex: selectedColorHex,
          habitNotes: notes,
        );

        // Call the notifier method to update the database record
        notifier.updateHabit(updatedHabit);
      } else {
        // 2. CREATE LOGIC: Keep existing creation flow
        notifier.addHabit(
          title,
          habitNotes: notes,
          reminderTime: reminderTime,
          colorHex: selectedColorHex,
        );
      }

      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = widget.useKeyboardInset
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 12 + keyboard),
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
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. Read before bed, no phone',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reminder'),
            subtitle: Text(_reminderTime?.format(context) ?? 'Not set'),
            trailing: IconButton(
              tooltip: 'Choose reminder time',
              icon: const Icon(Icons.access_time),
              onPressed: _pickReminderDate,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 12),
          const SizedBox(height: 16),
          const Text(
            'Color',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: _colorOptions.map((color) {
              final isSelected = color == _selectedColor;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black87, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, child: const Text('Save Habit')),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
