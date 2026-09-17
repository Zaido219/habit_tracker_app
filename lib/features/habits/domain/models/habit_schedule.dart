enum ScheduleType{
  daily,
  weekly,
  monthly,
  custom;

  static ScheduleType fromString(String value){
    return ScheduleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ScheduleType.daily,
    );
  }
}

class HabitSchedule {
  final ScheduleType type;
  final List<int> targetDaysOrFrequency;
  final DateTime? startDate;
  final DateTime? endDate;


  const HabitSchedule({
    required this.type,
    this.targetDaysOrFrequency = const [],
    this.startDate,
    this.endDate
  });
}

extension HabitScheduleMatcher on HabitSchedule {
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whether [date] is a day this habit is expected to be done.
  bool isExpectedDay(DateTime date) {
    switch (type) {
      case ScheduleType.daily:
        return true;

      case ScheduleType.weekly:
        // targetDaysOrFrequency holds weekday ints, 1=Mon...7=Sun
        return targetDaysOrFrequency.contains(date.weekday);

      case ScheduleType.monthly:
        // targetDaysOrFrequency holds day-of-month ints
        return targetDaysOrFrequency.contains(date.day);

      case ScheduleType.custom:
        // targetDaysOrFrequency holds [intervalDays], e.g. every 3 days from startDate
        if (targetDaysOrFrequency.isEmpty || startDate == null) {
          return false;
        }
        final interval = targetDaysOrFrequency.first;
        final daysSinceStart = _dateOnly(date).difference(_dateOnly(startDate!)).inDays;
        return daysSinceStart >= 0 && daysSinceStart % interval == 0;
    }
  }
}