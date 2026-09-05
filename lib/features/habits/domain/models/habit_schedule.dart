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
