import 'package:drift/drift.dart';

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get color => text()();
  TextColumn get soundUri => text().nullable()();
  TextColumn get scheduleType => text()();
  TextColumn get scheduleConfig => text()();
  TextColumn get habitNotes => text()
    .withDefault(const Constant(''))();
  BoolColumn get isProtected => 
    boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => 
    dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isArchived =>
    boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}