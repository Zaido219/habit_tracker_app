import 'package:drift/drift.dart';
import 'habits.dart';

class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => 
    text().references(Habits, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get completedAt => 
    dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}