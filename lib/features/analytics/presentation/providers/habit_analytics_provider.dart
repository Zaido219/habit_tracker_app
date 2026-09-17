import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/calculators/streak_engine.dart';
import '../../domain/calculators/consistency_engine.dart';
import '../../../habits/domain/models/habit_schedule.dart';
import '../../../habits/presentation/providers/habit_repository_provider.dart';

class HabitAnalytics {
  final StreakStats streakStats;
  final ConsistencyStats consistencyStats;

  const HabitAnalytics({
    required this.streakStats,
    required this.consistencyStats,
  });
}

final habitAnalyticsProvider = StreamProvider.family<HabitAnalytics, ({String habitId, HabitSchedule schedule})>(
  (ref, args) {
    final repository = ref.watch(habitRepositoryProvider);

    return repository.watchLogsForHabit(args.habitId).map((logs) {
      final streakEngine = StreakEngine(schedule: args.schedule, logs: logs);
      final consistencyEngine = ConsistencyEngine(schedule: args.schedule, logs: logs);

      return HabitAnalytics(
        streakStats: streakEngine.computeAll(),
        consistencyStats: consistencyEngine.computeAll(),
      );
    });
  },
);