import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/habit_dashboard_provider.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_reminder.dart';
import '../../domain/models/habit_schedule.dart';

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
  List<HabitReminder> _existingReminders = [];
  bool _isLoadingReminders = false;
  bool _isSaving = false;
  String? _reminderLoadError;
  final _controller = TextEditingController();
  final _notesController = TextEditingController();
  final _customIntervalController = TextEditingController(text: '2');
  ScheduleType _selectedScheduleType = ScheduleType.daily;
  Set<int> _selectedWeekdays = {};
  int _selectedMonthDay = 1;

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.habitToEdit != null) {
      _controller.text = widget.habitToEdit!.title;
      _notesController.text = widget.habitToEdit!.habitNotes;
      final schedule = widget.habitToEdit!.schedule;
      _selectedScheduleType = schedule.type;
      _selectedWeekdays = schedule.type == ScheduleType.weekly
          ? schedule.targetDaysOrFrequency.toSet()
          : {};
      if (schedule.type == ScheduleType.monthly &&
          schedule.targetDaysOrFrequency.isNotEmpty) {
        _selectedMonthDay = schedule.targetDaysOrFrequency.first;
      }
      if (schedule.type == ScheduleType.custom &&
          schedule.targetDaysOrFrequency.isNotEmpty) {
        _customIntervalController.text = schedule.targetDaysOrFrequency.first
            .toString();
      }
      _isLoadingReminders = true;
      unawaited(_loadExistingReminders());
    }
  }

  Future<void> _loadExistingReminders() async {
    try {
      final reminders = await ref
          .read(habitDashboardProvider.notifier)
          .getRemindersForHabit(widget.habitToEdit!.id);
      if (!mounted) return;

      setState(() {
        _existingReminders = reminders;
        _reminderTime = reminders.isEmpty
            ? null
            : _parseReminderTime(reminders.first.targetTime);
        _isLoadingReminders = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _reminderLoadError = error.toString();
        _isLoadingReminders = false;
      });
    }
  }

  TimeOfDay _parseReminderTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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

  Future<void> _submit() async {
    if (_isSaving || _isLoadingReminders || _reminderLoadError != null) return;

    final title = _controller.text.trim();
    final notes = _notesController.text.trim();
    final customInterval = int.tryParse(_customIntervalController.text);
    if (_selectedScheduleType == ScheduleType.weekly &&
        _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose at least one day.')));
      return;
    }
    if (_selectedScheduleType == ScheduleType.custom &&
        (customInterval == null || customInterval < 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid interval of at least 1 day.'),
        ),
      );
      return;
    }

    final existingSchedule = widget.habitToEdit?.schedule;
    final schedule = switch (_selectedScheduleType) {
      ScheduleType.daily => const HabitSchedule(type: ScheduleType.daily),
      ScheduleType.weekly => HabitSchedule(
        type: ScheduleType.weekly,
        targetDaysOrFrequency: _selectedWeekdays.toList()..sort(),
      ),
      ScheduleType.monthly => HabitSchedule(
        type: ScheduleType.monthly,
        targetDaysOrFrequency: [_selectedMonthDay],
      ),
      ScheduleType.custom => HabitSchedule(
        type: ScheduleType.custom,
        targetDaysOrFrequency: [customInterval!],
        startDate: existingSchedule?.type == ScheduleType.custom
            ? existingSchedule!.startDate ?? DateTime.now()
            : DateTime.now(),
      ),
    };
    final time = _reminderTime;
    final reminderTime = time == null
        ? null
        : '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';

    if (title.isNotEmpty) {
      final notifier = ref.read(habitDashboardProvider.notifier);
      final selectedColorHex = _colorToHex(_selectedColor);
      final messenger = ScaffoldMessenger.of(context);

      setState(() => _isSaving = true);
      try {
        if (widget.habitToEdit != null) {
          final habit = widget.habitToEdit!;
          final updatedHabit = habit.copyWith(
            title: title,
            colorHex: selectedColorHex,
            habitNotes: notes,
            schedule: schedule,
          );

          await notifier.updateHabit(updatedHabit);

          final reminders = reminderTime == null
              ? <HabitReminder>[]
              : [
                  if (_existingReminders.isEmpty)
                    HabitReminder(
                      id: '${habit.id}_reminder',
                      habitId: habit.id,
                      leadTimeMinutes: 0,
                      targetTime: reminderTime,
                    )
                  else ...[
                    HabitReminder(
                      id: _existingReminders.first.id,
                      habitId: habit.id,
                      leadTimeMinutes: _existingReminders.first.leadTimeMinutes,
                      targetTime: reminderTime,
                    ),
                    ..._existingReminders.skip(1),
                  ],
                ];
          await notifier.syncReminders(habit.id, reminders);
        } else {
          await notifier.addHabit(
            title,
            habitNotes: notes,
            reminderTime: reminderTime,
            colorHex: selectedColorHex,
            schedule: schedule,
          );
        }

        if (!mounted) return;
        widget.onClose?.call();
      } catch (error) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Could not save habit: $error')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
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
          Text(
            widget.habitToEdit == null ? 'New Habit' : 'Edit habit',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
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
          DropdownButtonFormField<ScheduleType>(
            initialValue: _selectedScheduleType,
            decoration: const InputDecoration(
              labelText: 'Schedule',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: ScheduleType.daily, child: Text('Daily')),
              DropdownMenuItem(
                value: ScheduleType.weekly,
                child: Text('Weekly'),
              ),
              DropdownMenuItem(
                value: ScheduleType.monthly,
                child: Text('Monthly'),
              ),
              DropdownMenuItem(
                value: ScheduleType.custom,
                child: Text('Custom interval'),
              ),
            ],
            onChanged: (type) {
              if (type != null) {
                setState(() => _selectedScheduleType = type);
              }
            },
          ),
          if (_selectedScheduleType == ScheduleType.weekly) ...[
            const SizedBox(height: 12),
            const Text('Repeat on'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                for (final entry in const [
                  (1, 'Mon'),
                  (2, 'Tue'),
                  (3, 'Wed'),
                  (4, 'Thu'),
                  (5, 'Fri'),
                  (6, 'Sat'),
                  (7, 'Sun'),
                ])
                  FilterChip(
                    label: Text(entry.$2),
                    selected: _selectedWeekdays.contains(entry.$1),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWeekdays.add(entry.$1);
                        } else {
                          _selectedWeekdays.remove(entry.$1);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
          if (_selectedScheduleType == ScheduleType.monthly) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedMonthDay,
              decoration: const InputDecoration(
                labelText: 'Day of the month',
                border: OutlineInputBorder(),
              ),
              items: [
                for (var day = 1; day <= 31; day++)
                  DropdownMenuItem(value: day, child: Text('$day')),
              ],
              onChanged: (day) {
                if (day != null) setState(() => _selectedMonthDay = day);
              },
            ),
          ],
          if (_selectedScheduleType == ScheduleType.custom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customIntervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Repeat every (days)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reminder'),
            subtitle: Text(
              _isLoadingReminders
                  ? 'Loading reminder...'
                  : _reminderTime?.format(context) ?? 'Not set',
            ),
            trailing: IconButton(
              tooltip: 'Choose reminder time',
              icon: const Icon(Icons.access_time),
              onPressed: _isLoadingReminders || _reminderLoadError != null
                  ? null
                  : _pickReminderDate,
            ),
          ),
          if (_reminderLoadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Could not load existing reminder: $_reminderLoadError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
          ElevatedButton(
            onPressed:
                _isSaving || _isLoadingReminders || _reminderLoadError != null
                ? null
                : _submit,
            child: Text(_isSaving ? 'Saving...' : 'Save Habit'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
