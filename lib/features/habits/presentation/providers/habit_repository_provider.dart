import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../data/repositories/habit_repository_impl.dart';
import '../../../../core/database/app_database.dart';

// Provider for the AppDatabase instance
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Provider for HabitRepository
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return HabitRepositoryImpl(
    db: db,
    habitDao: db.habitDao,
    habitLogDao: db.habitLogDao,
    habitReminderDao: db.habitReminderDao,
  );
});