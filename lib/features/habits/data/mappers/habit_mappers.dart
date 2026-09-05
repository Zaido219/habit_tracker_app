import 'package:drift/drift.dart';
import 'package:habit_tracker_app/features/habits/domain/models/habit_schedule.dart';

// Import raw Drift DataClasses (alias if needed)
import '../../../../core/database/app_database.dart' as db;
// Import Domain Entities
import '../../domain/models/habit.dart';

extension HabitDataMapper on db.Habit {
  Habit toDomain() {
    return Habit(
      id: id,
      title: title,
      colorHex: color,             // Map DB 'color' -> Domain 'colorHex'
      soundUri: soundUri,
      isProtected: isProtected,    // Don't forget missing required fields
      position: position,
      createdAt: createdAt,
      schedule: HabitSchedule.fromStorage(
        type: scheduleType,
        config: scheduleConfig,
      ), // Reconstruct your Domain object from DB strings
    );
  }
}

extension HabitDomainMapper on Habit {
  db.HabitsCompanion toCompanion() {
    return db.HabitsCompanion.insert(
      id: Value(id),
      title: title,
      color: colorHex,             // Map Domain 'colorHex' -> DB 'color'
      soundUri: Value(soundUri),
      scheduleType: schedule.type, // Extract string from HabitSchedule
      scheduleConfig: schedule.configJson, // Convert config to JSON string
      isProtected: Value(isProtected),
      position: position,
      createdAt: Value(createdAt),
    );
  }
}