import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart'
    hide Habit, HabitLog, HabitReminder;
import '../../../../core/database/daos/habit_dao.dart';
import '../../../../core/database/daos/habit_log_dao.dart';
import '../../../../core/database/daos/habit_reminder_dao.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/models/habit_reminder.dart';
import '../../domain/repositories/habit_repository.dart';
import '../mappers/habit_mappers.dart';
import '../mappers/habit_reminder_mappers.dart';

class HabitRepositoryImpl implements HabitRepository {
  final AppDatabase _db;
  final HabitDao _habitDao;
  final HabitLogDao _habitLogDao;
  final HabitReminderDao _habitReminderDao;

  HabitRepositoryImpl({
    required this._db,
    required this._habitDao,
    required this._habitLogDao,
    required this._habitReminderDao,
  });

  @override
  Stream<List<Habit>> watchAllHabits() {
    return _habitDao.watchAll().map(
      (driftHabits) => driftHabits.map((h) => h.toDomain()).toList(),
    );
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    final habitData = await _habitDao.getById(id);
    return habitData?.toDomain();
  }

  @override
  Future<void> createHabit({
    required Habit habit,
    List<HabitReminder> reminders = const [],
  }) async {
    // Atomic transaction ensures habit and its initial reminders succeed or fail together
    await _db.transaction(() async {
      await _habitDao.create(habit.toCompanion());
      for (final reminder in reminders) {
        await _habitReminderDao.create(reminder.toCompanion());
      }
    });
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _habitDao.updateHabit(habit.id,habit.toCompanion());
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _habitDao.deleteById(habitId);
  }

  @override
  Future<void> updateHabitPositions(List<Habit> reorderedHabits) async {
    await _db.transaction(() async {
      for (int i = 0; i < reorderedHabits.length; i++) {
        final habit = reorderedHabits[i].copyWith(position: i);
        await _habitDao.updateHabit(habit.id, habit.toCompanion());
      }
    });
  }

  @override
  Stream<List<HabitLog>> watchLogsForHabit(
    String habitId, {
    DateTime? from,
    DateTime? to,
  }) {
    return _habitLogDao
        .watchForHabit(habitId)
        .map((driftLogs) => driftLogs.map((l) => l.toDomain()).toList());
  }

  @override
  Future<void> logCompletion(String habitId, DateTime timestamp) async {
    await _habitLogDao.create(
      HabitLogsCompanion.insert(
        id: Value(DateTime.now().millisecondsSinceEpoch.toString()),
        habitId: habitId,
        completedAt: timestamp,
      ),
    );
  }

  @override
  Future<void> removeLog(String logId) async {
    await _habitLogDao.deleteById(logId);
  }

  @override
  Future<List<HabitReminder>> getRemindersForHabit(String habitId) async {
    final driftReminders = await _habitReminderDao.getByHabitId(habitId);
    return driftReminders.map((r) => r.toDomain()).toList();
  }

  @override
  Future<void> syncReminders(
    String habitId,
    List<HabitReminder> reminders,
  ) async {
    await _db.transaction(() async {
      await _habitReminderDao.deleteByHabitId(habitId);
      for (final reminder in reminders) {
        await _habitReminderDao.create(reminder.toCompanion());
      }
    });
  }
}
