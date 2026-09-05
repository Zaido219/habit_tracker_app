import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/habit_logs.dart';

part 'habit_log_dao.g.dart';

@DriftAccessor(tables: [HabitLogs])
class HabitLogDao extends DatabaseAccessor<AppDatabase>
    with _$HabitLogDaoMixin {
  HabitLogDao(super.db);

  /// Get all logs for a habit.
  Future<List<HabitLog>> getForHabit(String habitId) {
    return (select(habitLogs)
          ..where((log) => log.habitId.equals(habitId))
          ..orderBy([
            (log) => OrderingTerm(
                  expression: log.completedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Watch logs for a habit.
  Stream<List<HabitLog>> watchForHabit(String habitId) {
    return (select(habitLogs)
          ..where((log) => log.habitId.equals(habitId))
          ..orderBy([
            (log) => OrderingTerm(
                  expression: log.completedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  /// Get a single log.
  Future<HabitLog?> getById(String id) {
    return (select(habitLogs)
          ..where((log) => log.id.equals(id)))
        .getSingleOrNull();
  }

  /// Record a habit completion.
  Future<void> create(HabitLogsCompanion log) {
    return into(habitLogs).insert(log);
  }

  /// Delete a completion record.
  Future<int> deleteById(String id) {
    return (delete(habitLogs)
          ..where((log) => log.id.equals(id)))
        .go();
  }

  /// Delete all logs belonging to a habit.
  Future<int> deleteForHabit(String habitId) {
    return (delete(habitLogs)
          ..where((log) => log.habitId.equals(habitId)))
        .go();
  }
}