import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/repositories/habit_repository.dart';
import '../models/habit_dashboard_state.dart';

// Modern Riverpod approach
class HabitDashboardNotifier extends Notifier<HabitDashboardState> {
  final HabitRepository _repository;
  StreamSubscription<List<Habit>>? _habitsSubscription;

  HabitDashboardNotifier(this._repository);

  @override
  HabitDashboardState build() {
    // Clean up subscriptions when provider rebuilds or disposes
    ref.onDispose(() {
      _habitsSubscription?.cancel();
    });

    _initialize();

    // Return initial state directly from build()
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

    // Check if a log already exists for this habit on this date
    final existingLog = state.logs.cast<HabitLog?>().firstWhere((log) {
      if (log == null || log.habitId != habitId) return false;
      final logDate = DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );
      return logDate.isAtSameMomentAs(targetDate);
    }, orElse: () => null);

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
    NotifierProvider<HabitDashboardNotifier, HabitDashboardState>(() {
      // In Riverpod 2+, repositories are usually provided via another provider:
      // final repository = ref.watch(habitRepositoryProvider);
      // return HabitDashboardNotifier(repository);
      throw UnimplementedError('Provide your HabitRepository instance here');
    });
