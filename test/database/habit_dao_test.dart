import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Adjust these imports to match your project's directory path
import 'package:habit_tracker_app/core/database/app_database.dart';
import 'package:habit_tracker_app/core/database/daos/habit_dao.dart';

void main() {
  late AppDatabase database;
  late HabitDao habitDao;

  setUp(() {
    // Instantiate an isolated, in-memory database for each test run
    database = AppDatabase();
    habitDao = HabitDao(database);
  });

  tearDown(() async {
    // Clean up connections after each test
    await database.close();
  });

  group('HabitDao Tests', () {
    test('create and getById retrieves the inserted habit correctly', () async {
      final companion = HabitsCompanion.insert(
        id: 'habit_1',
        title: 'Morning Run',
        color: '#FF0000',
        scheduleType: 'daily',
        scheduleConfig: '{}',
        position: 0,
      );

      await habitDao.create(companion);
      final retrieved = await habitDao.getById('habit_1');

      expect(retrieved, isNotNull);
      expect(retrieved?.id, equals('habit_1'));
      expect(retrieved?.title, equals('Morning Run'));
    });

    test('getAll returns habits ordered by position index', () async {
      // Insert habits out of position order
      await habitDao.create(HabitsCompanion.insert(
        id: 'habit_b',
        title: 'Read Book',
        color: '#00FF00',
        scheduleType: 'daily',
        scheduleConfig: '{}',
        position: 2,
      ));

      await habitDao.create(HabitsCompanion.insert(
        id: 'habit_a',
        title: 'Drink Water',
        color: '#0000FF',
        scheduleType: 'daily',
        scheduleConfig: '{}',
        position: 1,
      ));

      final habits = await habitDao.getAll();

      expect(habits.length, equals(2));
      expect(habits.first.id, equals('habit_a')); // position 1 comes before position 2
      expect(habits.last.id, equals('habit_b'));
    });

    test('watchAll emits a new list when a habit is added', () async {
      final stream = habitDao.watchAll();

      // Expect initial empty state and subsequent update when inserted
      expect(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );

      await habitDao.create(HabitsCompanion.insert(
        id: 'habit_stream_1',
        title: 'Meditate',
        color: '#FFFF00',
        scheduleType: 'daily',
        scheduleConfig: '{}',
        position: 0,
      ));
    });

    test('updateHabit correctly modifies fields', () async {
      await habitDao.create(HabitsCompanion.insert(
        id: 'habit_update',
        title: 'Old Title',
        color: '#000000',
        scheduleType: 'daily',
        scheduleConfig: '{}',
        position: 0,
      ));

      final success = await habitDao.updateHabit(
        'habit_update',
        const HabitsCompanion(title: Value('New Title')),
      );

      final updated = await habitDao.getById('habit_update');

      expect(success, isTrue);
      expect(updated?.title, equals('New Title'));
    });

    test('deleteById removes the target habit', () async {
      await habitDao.create(HabitsCompanion.insert(
        id: 'habit_delete',
        title: 'Temporary Habit',
        color: '#FFFFFF',
        scheduleType: 'daily',
        scheduleConfig: '{}',
        position: 0,
      ));

      final deletedRows = await habitDao.deleteById('habit_delete');
      final result = await habitDao.getById('habit_delete');

      expect(deletedRows, equals(1));
      expect(result, isNull);
    });
  });
}