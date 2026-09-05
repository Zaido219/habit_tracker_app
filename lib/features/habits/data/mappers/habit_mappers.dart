import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../domain/models/habit.dart';
import '../../domain/models/habit_schedule.dart';

extension HabitDataMapper on db.Habit {
  Habit toDomain() {
    return Habit(
      id: id,
      title: title,
      colorHex: color,
      soundUri: soundUri,
      isProtected: isProtected,
      position: position,
      createdAt: createdAt,
      // Uses the new deserializer
      schedule: HabitScheduleStorage.fromStorage(
        scheduleType,
        scheduleConfig,
      ),
    );
  }
}

extension HabitDomainMapper on Habit {
  db.HabitsCompanion toCompanion() {
    return db.HabitsCompanion.insert(
      id: id, // Pass raw String if column is not wrapped in Value
      title: title,
      color: colorHex,
      soundUri: Value(soundUri),
      scheduleType: schedule.type.name, // Extract enum String name ('daily', 'weekly')
      scheduleConfig: schedule.toConfigJson(), // Converts List<int> to JSON String
      isProtected: Value(isProtected),
      position: position,
      createdAt: Value(createdAt),
    );
  }
}