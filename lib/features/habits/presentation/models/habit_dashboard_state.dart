import "../../domain/models/habit.dart";
import "../../domain/models/habit_log.dart";

// This code defines an immutable UI state model for your habit dashboard screen.
//It acts as a single, centralized "data snapshot" holding every piece of information your 
//dashboard UI needs to render itself at any given second.
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