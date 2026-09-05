import 'habit_schedule.dart';

class Habit {
  final String id;
  final String title;
  final String colorHex;
  final String? soundUri;
  final HabitSchedule schedule;
  final bool isProtected;
  final int position;
  final DateTime createdAt;


  const Habit({
    required this.id,
    required this.title,
    required this.colorHex,
    this.soundUri,
    required this.schedule,
    required this.isProtected,
    required this.position,
    required this.createdAt,

  });

  /// Useful for returning masked state in the ViewModel when biometrics are locked
  Habit copyWithRedactedTitle(String placeholder) {
    return Habit(
      id: id,
      title: placeholder,
      colorHex: colorHex,
      soundUri: soundUri,
      schedule: schedule,
      isProtected: isProtected,
      position: position,
      createdAt: createdAt,
    );
  }

  Habit copyWith({
  String? id,
  String? title,
  String? colorHex,
  String? soundUri,
  HabitSchedule? schedule,
  bool? isProtected,
  int? position,
  DateTime? createdAt,
}) {
  return Habit(
    id: id ?? this.id,
    title: title ?? this.title,
    colorHex: colorHex ?? this.colorHex,
    soundUri: soundUri ?? this.soundUri,
    schedule: schedule ?? this.schedule,
    isProtected: isProtected ?? this.isProtected,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );
}
}