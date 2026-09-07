import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_app/features/habits/presentation/widgets/create_habit_bottom_sheet.dart';
import 'package:intl/intl.dart';
import '../providers/habit_dashboard_provider.dart';

class HabitDashboardScreen extends ConsumerWidget {
  const HabitDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen to state changes from habitDashboardProvider
    final state = ref.watch(habitDashboardProvider);
    final notifier = ref.read(habitDashboardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, 
                builder: (context) => const CreateHabitBottomSheet(),
                );
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.habits.isEmpty
              ? const Center(child: Text('No habits yet. Tap + to add one!'))
              : Column(
                  children: [
                    // Date Header Row
                    _buildDateHeader(state.visibleDates),
                    const Divider(height: 1),
                    // Habit Grid List
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.habits.length,
                        itemBuilder: (context, index) {
                          final habit = state.habits[index];
                          return _buildHabitRow(
                            context: context,
                            habit: habit,
                            visibleDates: state.visibleDates,
                            state: state,
                            onToggleDate: (date) {
                              notifier.toggleHabitLog(habit.id, date);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDateHeader(List<DateTime> visibleDates) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: SizedBox.shrink(), // Spacer for habit title column
          ),
          ...visibleDates.map(
            (date) => Expanded(
              flex: 1,
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(), // e.g. "MON"
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d').format(date), // e.g. "7"
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitRow({
    required BuildContext context,
    required habit,
    required List<DateTime> visibleDates,
    required state,
    required Function(DateTime) onToggleDate,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          // Habit Title
          Expanded(
            flex: 3,
            child: Text(
              habit.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Checkmark Buttons Matrix
          ...visibleDates.map((date) {
            final targetDate = DateTime(date.year, date.month, date.day);
            final isCompleted = state.logs.any((log) {
              if (log.habitId != habit.id) return false;
              final logDate = DateTime(
                log.completedAt.year,
                log.completedAt.month,
                log.completedAt.day,
              );
              return logDate.isAtSameMomentAs(targetDate);
            });

            return Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => onToggleDate(date),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.deepPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCompleted ? Colors.deepPurple : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}