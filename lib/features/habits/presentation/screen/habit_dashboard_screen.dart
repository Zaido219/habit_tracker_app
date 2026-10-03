import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_app/features/habits/presentation/widgets/create_habit_bottom_sheet.dart';
import 'package:intl/intl.dart';

import 'habit_detail_screen.dart';
import '../providers/habit_dashboard_provider.dart';

import 'package:habit_tracker_app/features/habits/domain/models/habit.dart';
import 'package:habit_tracker_app/core/notifications/notification_service.dart';

class HabitDashboardScreen extends ConsumerStatefulWidget {
  const HabitDashboardScreen({super.key});

  @override
  ConsumerState<HabitDashboardScreen> createState() =>
      _HabitDashboardScreenState();
}

class _HabitDashboardScreenState extends ConsumerState<HabitDashboardScreen> {
  Habit? _selectedHabit;

  PersistentBottomSheetController? _bottomSheetController;

  // Width of the fixed habit-name column.
  static const double _habitNameWidth = 180.0;

  // Width of each date column.
  static const double _dateColumnWidth = 60.0;

  // Controls horizontal scrolling of the dates.
  final ScrollController _horizontalController = ScrollController();

  // These two control vertical scrolling.
  final ScrollController _leftVerticalController = ScrollController();

  final ScrollController _rightVerticalController = ScrollController();

  bool _isSyncingVertical = false;

  @override
  void initState() {
    super.initState();

    _leftVerticalController.addListener(_syncLeftToRight);

    _rightVerticalController.addListener(_syncRightToLeft);
  }

  void _syncLeftToRight() {
    if (_isSyncingVertical) return;

    if (!_rightVerticalController.hasClients) return;

    _isSyncingVertical = true;

    _rightVerticalController.jumpTo(
      _leftVerticalController.offset.clamp(
        0.0,
        _rightVerticalController.position.maxScrollExtent,
      ),
    );

    _isSyncingVertical = false;
  }

  void _syncRightToLeft() {
    if (_isSyncingVertical) return;

    if (!_leftVerticalController.hasClients) return;

    _isSyncingVertical = true;

    _leftVerticalController.jumpTo(
      _rightVerticalController.offset.clamp(
        0.0,
        _leftVerticalController.position.maxScrollExtent,
      ),
    );

    _isSyncingVertical = false;
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();

    super.dispose();
  }

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

  void _showEditHabitBottomSheet(BuildContext context, Habit habit) {
    _bottomSheetController = showBottomSheet(
      context: context,
      builder: (context) => CreateHabitBottomSheet(
        habitToEdit: habit,
        useKeyboardInset: false, // scaffold already handles the keyboard
        onClose: () {
          _bottomSheetController?.close();
        },
      ),
    );

    _bottomSheetController!.closed.then((_) {
      _bottomSheetController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitDashboardProvider);

    final notifier = ref.read(habitDashboardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedHabit == null ? 'Habits' : _selectedHabit!.title),
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
              tooltip: 'Delete habit',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final habit = _selectedHabit!;

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete habit?'),
                    content: Text(
                      'Delete "${habit.title}" and its completion history? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true || !mounted) return;

                _bottomSheetController?.close();
                await notifier.deleteHabit(habit.id);

                if (mounted) {
                  setState(() => _selectedHabit = null);
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
                  builder: (sheetContext) => CreateHabitBottomSheet(
                    onClose: () => Navigator.pop(sheetContext),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Test notification',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () async {
              await NotificationService.showTestNotification();
            },
          ),
        ],
      ),

      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.habits.isEmpty
          ? const Center(child: Text('No habits yet. Tap + to add one!'))
          : _buildHabitTable(context, state, notifier),
    );
  }

  Widget _buildHabitTable(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    final totalDateWidth = state.visibleDates.length * _dateColumnWidth;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // =====================================================
        // FIXED LEFT SIDE
        // =====================================================

        SizedBox(
          width: _habitNameWidth,
          child: Column(
            children: [
              // Header above habit names.
              const SizedBox(
                height: 70,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'Habits',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Habit names.
              Expanded(
                child: ListView.builder(
                  controller: _leftVerticalController,
                  itemCount: state.habits.length,
                  itemBuilder: (context, index) {
                    final habit = state.habits[index];

                    return _buildHabitNameRow(context, habit);
                  },
                ),
              ),
            ],
          ),
        ),

        // =====================================================
        // RIGHT SIDE - HORIZONTALLY SCROLLABLE
        // =====================================================
        Expanded(
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,

            child: SizedBox(
              width: totalDateWidth,

              child: Column(
                children: [
                  // DATE HEADER
                  _buildDateHeader(state.visibleDates),

                  const Divider(height: 1),

                  // CHECKBOXES
                  Expanded(
                    child: ListView.builder(
                      controller: _rightVerticalController,
                      itemCount: state.habits.length,
                      itemBuilder: (context, index) {
                        final habit = state.habits[index];

                        return _buildCheckboxRow(
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
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // FIXED HABIT NAME ROW
  // ===========================================================
  Widget _buildHabitNameRow(BuildContext context, Habit habit) {
    final isSelected = _selectedHabit?.id == habit.id;

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque, // empty space in the row is tappable too
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitDetailScreen(habit: habit),
          ),
        );
      },
      onLongPress: () {
        setState(() {
          _selectedHabit = habit;
        });

        _showEditHabitBottomSheet(context, habit);
      },
      child: Container(
        height: 57,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : null,
          border: const Border(
            bottom: BorderSide(color: Colors.black12, width: 0.5),
          ),
        ),
        child: Text(
          habit.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ===========================================================
  // DATE HEADER
  // ===========================================================

  Widget _buildDateHeader(List<DateTime> visibleDates) {
    return SizedBox(
      height: 70,

      child: Row(
        children: [
          ...visibleDates.map(
            (date) => SizedBox(
              width: _dateColumnWidth,

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),

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

  // ===========================================================
  // CHECKBOX ROW
  // ===========================================================

  Widget _buildCheckboxRow({
    required BuildContext context,
    required Habit habit,
    required List<DateTime> visibleDates,
    required dynamic state,
    required Function(DateTime) onToggleDate,
  }) {
    final habitColor = _parseHabitColor(habit.colorHex);

    final isSelected = _selectedHabit?.id == habit.id;

    return Container(
      height: 57,

      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
            : null,

        border: const Border(
          bottom: BorderSide(color: Colors.black12, width: 0.5),
        ),
      ),

      child: Row(
        children: [
          ...visibleDates.map((date) {
            final targetDate = DateTime(date.year, date.month, date.day);

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

            return SizedBox(
              width: _dateColumnWidth,

              child: GestureDetector(
                onTap: () => onToggleDate(date),

                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    // below are the checkboxes sizes
                    width: 22,
                    height: 22,

                    decoration: BoxDecoration(
                      color: isCompleted ? habitColor : Colors.transparent,

                      borderRadius: BorderRadius.circular(5),

                      border: Border.all(
                        color: isCompleted
                            ? habitColor
                            : habitColor.withValues(alpha: 0.5),

                        width: 1.5,
                      ),
                    ),

                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
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
