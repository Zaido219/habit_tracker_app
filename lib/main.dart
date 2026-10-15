import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/habits/presentation/screen/habit_dashboard_screen.dart';
import 'core/notifications/notification_service.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  assert(() {
    debugPrintRebuildDirtyWidgets = true;
    debugProfileBuildsEnabledUserWidgets = true;
    return true;
  }());

  runApp(
    //providerScope stores the state of all riverpod providers
    const ProviderScope(child: HabitTrackerApp())
  );
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: HabitDashboardScreen(),
    );
  }
}