import "../../domain/models/habit.dart";
import "../../domain/models/habit_log.dart";

class HabitDashboardState{
  final List<Habit> habits;
  final List<HabitLog> logs;
  final List<DateTime> visibleDates;
  final bool isLoading;

  const HabitDashboardState({
    this.habits = const [],
    this.logs = const [],
    this.visibleDates = const [],
    this.isLoading = true,
  });

  HabitDashboardState copyWith({
    List<Habit>? habits,
    List<HabitLog>? logs,
    List<DateTime>? visibleDates,
    bool? isLoading,
  }){
    return HabitDashboardState(
      habits: habits ?? this.habits,
      logs: logs ?? this.logs,
      visibleDates: visibleDates ?? this.visibleDates,
      isLoading:  isLoading ?? this.isLoading
    );
  }
}