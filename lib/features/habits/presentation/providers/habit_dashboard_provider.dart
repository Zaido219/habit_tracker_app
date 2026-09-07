import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/repositories/habit_repository.dart';
import '../models/habit_dashboard_state.dart';
import './habit_repository_provider.dart';

// Assume you have a provider exposing your HabitRepository implementation
// final habitRepositoryProvider = Provider<HabitRepository>((ref) => ...);

class HabitDashboardNotifier extends Notifier<HabitDashboardState> {
  late final HabitRepository _repository;
  StreamSubscription<List<Habit>>? _habitsSubscription;

  @override
  HabitDashboardState build() {
    // 1. Inject the repository using ref
    _repository = ref.watch(habitRepositoryProvider);

    // 2. Register teardown logic instead of using a dispose() method
    ref.onDispose(() {
      _habitsSubscription?.cancel();
    });

    _initialize();

    // 3. Return initial state directly
    return const HabitDashboardState();
  }

  void _initialize() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visibleDates = List.generate(
      5,
      (index) => today.subtract(Duration(days: index)),
    );

    state = state.copyWith(visibleDates: visibleDates, isLoading: true);

    _habitsSubscription = _repository.watchAllHabits().listen((habits) {
      state = state.copyWith(habits: habits, isLoading: false);
    });
  }

  /// Toggles completion for a given habit on a specific date
  Future<void> toggleHabitLog(String habitId, DateTime date) async {
    final targetDate = DateTime(date.year, date.month, date.day);

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

    state = state.copyWith(habits: updatedList);

    await _repository.updateHabitPositions(updatedList);
  }
}

// Corrected Provider declaration
final habitDashboardProvider =
    NotifierProvider<HabitDashboardNotifier, HabitDashboardState>(
  HabitDashboardNotifier.new,
);