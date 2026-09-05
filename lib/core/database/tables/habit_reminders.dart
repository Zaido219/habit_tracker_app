import 'package:drift/drift.dart';
import 'habits.dart';


class HabitReminders extends Table {
  TextColumn get id => text()();

  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  IntColumn get leadTimeMinutes => integer()();

  TextColumn get targetTime => text()();
  
  @override
  Set<Column> get primaryKey => {id};
}