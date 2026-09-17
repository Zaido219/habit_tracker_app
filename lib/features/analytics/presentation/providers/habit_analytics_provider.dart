import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/calculators/streak_engine.dart';
import '../../domain/calculators/consistency_engine.dart';
import '../../../habits/domain/models/habit_schedule.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/habit_log_dao.dart';
class HabitAnalytics {
  final StreakStats streakStats;
  final ConsistencyStats consistencyStats;

  const HabitAnalytics({
    required this.streakStats,
    required this.consistencyStats,
  });
}

// Adjust this to however you already expose your DAO via Riverpod
final habitLogDaoProvider = Provider<HabitLogDao>((ref) {
  throw UnimplementedError('Override this with your actual DAO provider');
});

final habitAnalyticsProvider = StreamProvider.family<HabitAnalytics, ({String habitId, HabitSchedule schedule})>(
  (ref, args) {
    final dao = ref.watch(habitLogDaoProvider);

    return dao.watchForHabit(args.habitId).map((logs) {
      final streakEngine = StreakEngine(schedule: args.schedule, logs: logs);
      final consistencyEngine = ConsistencyEngine(schedule: args.schedule, logs: logs);

      return HabitAnalytics(
        streakStats: streakEngine.computeAll(),
        consistencyStats: consistencyEngine.computeAll(),
      );
    });
  },
);