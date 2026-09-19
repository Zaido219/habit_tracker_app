import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_dashboard_provider.dart';
import '../../domain/models/habit.dart';

class CreateHabitBottomSheet extends ConsumerStatefulWidget {
  final Habit? habitToEdit; // pass a habit object if editing
  const CreateHabitBottomSheet({
    super.key,
    this.habitToEdit});

  @override
  ConsumerState<CreateHabitBottomSheet> createState() =>
      _CreateHabitBottomSheetState();
}

class _CreateHabitBottomSheetState
    extends ConsumerState<CreateHabitBottomSheet> {
    final _controller = TextEditingController();

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState(){
    super.initState();
    if(widget.habitToEdit != null){
      _controller.text = widget.habitToEdit!.title;
    }
  }

  String _colorToHex(Color color) {
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  void _submit() {
    final title = _controller.text;
    if (title.trim().isNotEmpty) {
      ref.read(habitDashboardProvider.notifier).addHabit(
            title,
            colorHex: _colorToHex(_selectedColor),
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            onPressed: _submit,
            child: const Text('Save Habit'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}