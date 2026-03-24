import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'providers/workout_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/floating_timer.dart';
import 'theme/app_theme.dart';
import 'screens/auth_wrapper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://riajsrglchsmpmajlgrv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpYWpzcmdsY2hzbXBtYWpsZ3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMDQ3MjAsImV4cCI6MjA4OTg4MDcyMH0.Vpu4fKw8fHIh0D-RIZ4Vm23rTH4yzFvpfzf56RzCU6w',
  );

  if (!kIsWeb) {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  runApp(const HitchTeamLiteApp());
}

class HitchTeamLiteApp extends StatelessWidget {
  const HitchTeamLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: MaterialApp(
        title: 'Hitch Team',
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return FloatingTimerOverlay(child: child!);
        },
      ),
    );
  }
}
