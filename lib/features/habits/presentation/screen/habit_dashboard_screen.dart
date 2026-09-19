import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_app/features/habits/presentation/widgets/create_habit_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'habit_detail_screen.dart';
import '../providers/habit_dashboard_provider.dart';
import 'package:habit_tracker_app/features/habits/domain/models/habit.dart';

class HabitDashboardScreen extends ConsumerStatefulWidget {
  const HabitDashboardScreen({super.key});

  @override
  ConsumerState<HabitDashboardScreen> createState() =>
      _HabitDashboardScreenState();
}

class _HabitDashboardScreenState
    extends ConsumerState<HabitDashboardScreen> {

  Habit? _selectedHabit;
  PersistentBottomSheetController? _bottomSheetController;

  Color _parseHabitColor(String colorHex) {
    var hex = colorHex
        .replaceFirst('#', '')
        .replaceFirst('0x', '')
        .replaceFirst('0X', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    return Color(int.parse(hex, radix: 16));
  }

  void _showEditHabitBottomSheet(
    BuildContext context,
    Habit habit,
  ) {
    _bottomSheetController = showBottomSheet(
      context: context,
      builder: (context) => CreateHabitBottomSheet(
        habitToEdit: habit,
        onClose: (){
          _bottomSheetController?.close();
        },
      ),
    );
    _bottomSheetController!.closed.then((_){
      _bottomSheetController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitDashboardProvider);
    final notifier = ref.read(habitDashboardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedHabit == null
              ? 'Habits'
              : _selectedHabit!.title,
        ),
        actions: [
          if (_selectedHabit != null) ...[
            IconButton(
              tooltip: 'Archive habit',
              icon: const Icon(Icons.archive_outlined),
              onPressed: () async {
                final habitId = _selectedHabit!.id;

                await notifier.archiveHabit(habitId);

                if (mounted) {
                  setState(() {
                    _selectedHabit = null;
                  });
                }
              },
            ),

            IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedHabit = null;
                });
              },
            ),
          ] else
            IconButton(
              tooltip: 'Add habit',
              icon: const Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) =>
                      const CreateHabitBottomSheet(),
                );
              },
            ),
        ],
      ),

      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : state.habits.isEmpty
              ? const Center(
                  child: Text(
                    'No habits yet. Tap + to add one!',
                  ),
                )
              : Column(
                  children: [
                    _buildDateHeader(state.visibleDates),

                    const Divider(height: 1),

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
                              notifier.toggleHabitLog(
                                habit.id,
                                date,
                              );
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
      padding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: SizedBox.shrink(),
          ),

          ...visibleDates.map(
            (date) => Expanded(
              flex: 1,
              child: Column(
                children: [
                  Text(
                    DateFormat('E')
                        .format(date)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    DateFormat('d').format(date),
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
    required Habit habit,
    required List<DateTime> visibleDates,
    required dynamic state,
    required Function(DateTime) onToggleDate,
  }) {
    final habitColor = _parseHabitColor(habit.colorHex);

    debugPrint(
      '${habit.title}: '
      'raw=${habit.colorHex}, '
      'parsed=$habitColor',
    );

    final isSelected = _selectedHabit?.id == habit.id;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.08)
            : null,
        border: const Border(
          bottom: BorderSide(
            color: Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HabitDetailScreen(habit: habit),
                  ),
                );
              },

              onLongPress: () {
                setState(() {
                  _selectedHabit = habit;
                });

                _showEditHabitBottomSheet(
                  context, 
                  habit,
                  );
              },

              child: Text(
                habit.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          ...visibleDates.map((date) {
            final targetDate = DateTime(
              date.year,
              date.month,
              date.day,
            );

            final isCompleted = state.logs.any((log) {
              if (log.habitId != habit.id) {
                return false;
              }

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
                    duration: const Duration(
                      milliseconds: 150,
                    ),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? habitColor
                          : Colors.transparent,

                      borderRadius:
                          BorderRadius.circular(6),

                      border: Border.all(
                        color: isCompleted
                            ? habitColor
                            : habitColor.withValues(
                                alpha: 0.5,
                              ),
                        width: 1.5,
                      ),
                    ),

                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
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