import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../domain/models/habit_log.dart';

extension HabitLogDataMapper on db.HabitLog {
  HabitLog toDomain() {
    return HabitLog(
      id: id,
      habitId: habitId,
      completedAt: completedAt,
    );
  }
}

extension HabitLogDomainMapper on HabitLog {
  db.HabitLogsCompanion toCompanion() {
    return db.HabitLogsCompanion.insert(
      id: id,
      habitId: habitId,
      completedAt: Value(completedAt),
    );
  }
}