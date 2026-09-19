import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habits.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits])
class HabitDao extends DatabaseAccessor<AppDatabase>
    with _$HabitDaoMixin {
  HabitDao(super.db);

  /// Get all habits ordered by their manual position.
  Future<List<Habit>> getAll() {
    return (select(habits)
          ..orderBy([
            (h) => OrderingTerm(expression: h.position),
          ]))
        .get();
  }

  /// Watch all habits.
  ///
  /// Useful for Flutter UI that should automatically update
  /// when the database changes.
  Stream<List<Habit>> watchAll() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(false))
          ..orderBy([
            (h) => OrderingTerm(expression: h.position),
          ]))
        .watch();
  }

  /// Get a single habit by ID.
  Future<Habit?> getById(String id) {
    return (select(habits)
          ..where((h) => h.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new habit.
  Future<void> create(HabitsCompanion habit) {
    return into(habits).insert(habit);
  }

  /// Update an existing habit.
  Future<bool> updateHabit(
    String id,
    HabitsCompanion changes,
  ) async {
    final updatedRows = await(update(habits)
    ..where((h) => h.id.equals(id)))
    .write(changes);

    return updatedRows > 0;
  }
  /// Delete a habit.
  ///
  /// Related logs and reminders will be deleted because
  /// their foreign keys use ON DELETE CASCADE.
  Future<int> deleteById(String id) {
    return (delete(habits)
          ..where((h) => h.id.equals(id)))
        .go();
  }

  /// Delete all habits.
  Future<int> deleteAll() {
    return delete(habits).go();
  }
  /// Archived a habit
  Future<bool> archiveHabit(String habitId) async{
    final updatedRows = await (update(habits)
    ..where((h) => h.id.equals(habitId)))
    .write(
      const HabitsCompanion(
        isArchived:Value(true),
        ),
      );
    return updatedRows > 0;
  }
}
