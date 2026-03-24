import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // For flutterLocalNotificationsPlugin

class TimerProvider with ChangeNotifier {
  int _remainingSeconds = 0;
  Timer? _timer;
  Timer? _ringingTimer;
  bool _isRunning = false;
  bool _isRinging = false;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isRinging => _isRinging;

  String get formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void startTimer(int seconds) {
    _timer?.cancel();
    _remainingSeconds = seconds;
    _isRunning = true;
    notifyListeners();
    
    _scheduleNotification(seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _isRunning = false;
        _startRinging();
      }
    });
  }

  void _startRinging() {
    _isRinging = true;

    if (!kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        id: 1,
        title: 'RECUPERO FINITO',
        body: 'Il tempo è scaduto! Torna a spingere!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_timer_instant',
            'Workout Timer Instant',
            channelDescription: 'Avvisi immediati fine recupero',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      Vibration.vibrate(pattern: [500, 1000]);
    }

    notifyListeners();
    _ringingTimer?.cancel();
    _ringingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      Vibration.vibrate(pattern: [500, 1000]);
    });
  }

  Future<void> _scheduleNotification(int seconds) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id: 0);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      title: 'RECUPERO FINITO',
      body: 'Il tuo tempo di recupero è scaduto!',
      scheduledDate: tz.TZDateTime.now(tz.UTC).add(Duration(seconds: seconds)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_timer',
          'Workout Timer',
          channelDescription: 'Avvisi fine recupero',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  void pauseTimer() {
    _timer?.cancel();
    flutterLocalNotificationsPlugin.cancel(id: 0);
    _isRunning = false;
    notifyListeners();
  }

  void resumeTimer() {
    if (_remainingSeconds > 0) {
      startTimer(_remainingSeconds);
    }
  }

  void stopRinging() {
    _isRinging = false;
    _ringingTimer?.cancel();
    Vibration.cancel();
    stop();
  }

  void stop() {
    _timer?.cancel();
    _ringingTimer?.cancel();
    _remainingSeconds = 0;
    _isRinging = false;
    if (!kIsWeb) flutterLocalNotificationsPlugin.cancelAll();
    _isRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringingTimer?.cancel();
    Vibration.cancel();
    super.dispose();
  }
}
