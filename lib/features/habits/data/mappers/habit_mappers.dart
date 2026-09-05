import 'package:drift/drift.dart';

// Import raw Drift DataClasses (alias if needed)
import '../../../../core/database/app_database.dart' as db;
// Import Domain Entities
import '../../domain/models/habit.dart';

extension HabitDataMapper on db.Habit {
  Habit toDomain() {
    return Habit(
      id: id,
      title: title,
      colorHex: color,
      scheduleType: scheduleType,
      scheduleConfig: scheduleConfig,
      position: position,
      createdAt: createdAt,
    );
  }
}

extension HabitDomainMapper on Habit {
  db.HabitsCompanion toCompanion() {
    return db.HabitsCompanion.insert(
      id: id,
      title: title,
      color: colorHex,
      scheduleType: scheduleType,
      scheduleConfig: scheduleConfig,
      position: position,
    );
  }
}