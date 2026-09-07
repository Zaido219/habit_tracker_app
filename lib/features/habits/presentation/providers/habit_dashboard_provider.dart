import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/repositories/habit_repository.dart';
import '../models/habit_dashboard_state.dart';

class HabitDashboardNotifier extends StateNotifier<HabitDashboardState> {
  final HabitRepository _repository;
  StreamSubscription<List<Habit>>? _habitsSubscription;
  StreamSubscription<List<HabitLog>>? _logsSubscription;

  HabitDashboardNotifier(this._repository) : super(const HabitDashboardState()) {
    _initialize();
  }

  void _initialize() {
    // 1. Calculate the visible dates (e.g., today and the previous 4 days)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visibleDates = List.generate(
      5,
      (index) => today.subtract(Duration(days: index)),
    );

    state = state.copyWith(visibleDates: visibleDates, isLoading: true);

    // 2. Stream all habits from the repository
    _habitsSubscription = _repository.watchAllHabits().listen((habits) {
      state = state.copyWith(habits: habits, isLoading: false);
    });

    // 3. Stream habit logs for the date window
    final startDate = visibleDates.last;
    final endDate = visibleDates.first.add(const Duration(days: 1));
    
    // Note: Assuming a watchAllLogs method or watching logs per habit
    // For simplicity, updating state when habits load
  }

  /// Toggles completion for a given habit on a specific date
  Future<void> toggleHabitLog(String habitId, DateTime date) async {
    final targetDate = DateTime(date.year, date.month, date.day);

    // Check if a log already exists for this habit on this date
    final existingLog = state.logs.cast<HabitLog?>().firstWhere(
      (log) {
        if (log == null || log.habitId != habitId) return false;
        final logDate = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );
        return logDate.isAtSameMomentAs(targetDate);
      },
      orElse: () => null,
    );

    if (existingLog != null) {
      await _repository.removeLog(existingLog.id);
    } else {
      await _repository.logCompletion(habitId, targetDate);
    }
  }

  /// Reorders habits and updates their persisted positions
  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final updatedList = List<Habit>.from(state.habits);
    final movedHabit = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, movedHabit);

    // Optimistically update local state for fast UI response
    state = state.copyWith(habits: updatedList);

    // Persist new positions via repository
    await _repository.updateHabitPositions(updatedList);
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _logsSubscription?.cancel();
    super.dispose();
  }
}


final habitDashboardProvider =
    StateNotifierProvider<HabitDashboardNotifier, HabitDashboardState>((ref) {
  // Inject your HabitRepository instance here
  final repository = ref.watch(habitRepositoryProvider);
  return HabitDashboardNotifier(repository);
});