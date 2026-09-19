import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker_app/features/habits/domain/models/habit_schedule.dart';

import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/repositories/habit_repository.dart';
import '../models/habit_dashboard_state.dart';
import 'habit_repository_provider.dart';

import 'package:rxdart/rxdart.dart';

class HabitDashboardNotifier extends Notifier<HabitDashboardState> {
  late final HabitRepository _repository;
  StreamSubscription<List<Habit>>? _habitsSubscription;
  StreamSubscription<List<HabitLog>>? _logsSubscription;

  @override
  HabitDashboardState build() {
    _repository = ref.watch(habitRepositoryProvider);

    // Cancel old subscriptions if build() is called again
    ref.onDispose(() {
      _habitsSubscription?.cancel();
    });

    // 1. Calculate initial visible dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visibleDates = List.generate(
      5,
      (index) => today.subtract(Duration(days: index)),
    );

    // 2. Start listening to repository streams AFTER initial build frame
    _subscribeToStreams();

    // 3. Return initial state directly (isLoading defaults to true)
    return HabitDashboardState(visibleDates: visibleDates, isLoading: true);
  }

  void _subscribeToStreams() {
    _habitsSubscription?.cancel();
    _logsSubscription?.cancel();

    _habitsSubscription = _repository.watchAllHabits().listen((habits) {
      state = state.copyWith(habits: habits, isLoading: false);
      _listenToLogsForHabits(habits);
    });
  }

  /// Toggles completion for a given habit on a specific date
  Future<void> toggleHabitLog(String habitId, DateTime date) async {
    final targetDate = DateTime(date.year, date.month, date.day);

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

    state = state.copyWith(habits: updatedList);

    await _repository.updateHabitPositions(updatedList);
  }

  /// Creates a new habit and persists it via the repository
  Future<void> addHabit(String title, {String colorHex = '0xFF6750A4'}) async {
    if (title.trim().isEmpty) return;

    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      position: state.habits.length,
      createdAt: DateTime.now(),
      colorHex: colorHex,
      schedule: HabitSchedule(type: ScheduleType.daily),
      isProtected: false,
    );

    await _repository.createHabit(habit: newHabit);
  }

  ///Listen to habit logs
  void _listenToLogsForHabits(List<Habit> habits) {
    _logsSubscription?.cancel();

    if (habits.isEmpty) {
      state = state.copyWith(logs: []);
      return;
    }

    final logStreams = habits.map((habit) {
      return _repository.watchLogsForHabit(habit.id);
    }).toList();

    _logsSubscription = CombineLatestStream.list(logStreams)
        .map((listOfLogLists) => listOfLogLists.expand((logs) => logs).toList())
        .listen((aggregatedLogs) {
          state = state.copyWith(logs: aggregatedLogs);
        });
  }
}

final habitDashboardProvider =
    NotifierProvider<HabitDashboardNotifier, HabitDashboardState>(
      HabitDashboardNotifier.new,
    );
