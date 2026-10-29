import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_app/features/habits/data/mappers/habit_schedule_mappers.dart';
import 'package:habit_tracker_app/features/habits/domain/models/habit_schedule.dart';

void main() {
  group('HabitScheduleStorage', () {
    test('round trips a custom interval and start date', () {
      final startDate = DateTime(2026, 1, 1);
      final schedule = HabitSchedule(
        type: ScheduleType.custom,
        targetDaysOrFrequency: const [3],
        startDate: startDate,
      );

      final restored = HabitScheduleStorage.fromStorage(
        ScheduleType.custom.name,
        schedule.toConfigJson(),
      );

      expect(restored.targetDaysOrFrequency, [3]);
      expect(restored.startDate, startDate);
      expect(restored.isExpectedDay(DateTime(2026, 1, 4)), isTrue);
      expect(restored.isExpectedDay(DateTime(2026, 1, 5)), isFalse);
    });

    test('reads legacy list configuration for weekly schedules', () {
      final restored = HabitScheduleStorage.fromStorage(
        ScheduleType.weekly.name,
        '[1, 3, 5]',
      );

      expect(restored.targetDaysOrFrequency, [1, 3, 5]);
      expect(restored.isExpectedDay(DateTime(2026, 1, 5)), isTrue);
      expect(restored.isExpectedDay(DateTime(2026, 1, 6)), isFalse);
    });

    test('uses the habit creation date for legacy custom schedules', () {
      final createdAt = DateTime(2026, 2, 1);
      final restored = HabitScheduleStorage.fromStorage(
        ScheduleType.custom.name,
        '[2]',
        fallbackStartDate: createdAt,
      );

      expect(restored.startDate, createdAt);
      expect(restored.isExpectedDay(DateTime(2026, 2, 3)), isTrue);
    });
  });
}
