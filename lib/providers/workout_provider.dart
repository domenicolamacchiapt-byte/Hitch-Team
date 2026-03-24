import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

class WorkoutProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Program> _programs = [];
  List<String> _dictionary = [];
  List<Map<String, dynamic>> _clients = [];
  String? _activeClientId;
  bool _programsLoaded = false;
  bool _clientsLoaded = false;
  
  List<Program> get programs => _programs;
  List<String> get dictionary => _dictionary;
  List<Map<String, dynamic>> get clients => _clients;
  String? get activeClientId => _activeClientId;
  bool get programsLoaded => _programsLoaded;
  bool get clientsLoaded => _clientsLoaded;

  WorkoutProvider();

  Future<void> loadPrograms({String? clientId, bool force = false}) async {
    if (_programsLoaded && !force && clientId == null) return;
    try {
      if (clientId != null) _activeClientId = clientId;
      _programs = await _db.getPrograms(specificUserId: _activeClientId);
      _dictionary = await _db.getDictionaryExercises();
      _programsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Skipped loading until authenticated: $e');
    }
  }

  Future<void> loadClients({bool force = false}) async {
    if (_clientsLoaded && !force) return;
    try {
      _clients = await _db.getClients();
      _clientsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading clients: $e');
    }
  }

  void clearActiveClient() {
    _activeClientId = null;
    _programs = [];
    _programsLoaded = false;
    notifyListeners();
  }

  Future<void> addToDictionary(String name) async {
    await _db.insertDictionaryExercise(name);
    _dictionary = await _db.getDictionaryExercises();
    notifyListeners();
  }

  Future<void> updateInDictionary(String oldName, String newName) async {
    await _db.updateDictionaryExercise(oldName, newName);
    _dictionary = await _db.getDictionaryExercises();
    notifyListeners();
  }

  Future<void> removeFromDictionary(String name) async {
    await _db.deleteDictionaryExercise(name);
    _dictionary = await _db.getDictionaryExercises();
    notifyListeners();
  }

  Future<void> addProgram(Program program) async {
    await _db.insertProgram(program, targetUserId: _activeClientId);
    await loadPrograms();
  }

  Future<void> updateProgram(Program program) async {
    await _db.updateProgram(program);
    await loadPrograms();
  }

  Future<void> deleteProgram(String id) async {
    await _db.deleteProgram(id);
    await loadPrograms();
  }

  Future<List<WorkoutDay>> getDaysForProgram(String programId) async {
    return await _db.getWorkoutDaysForProgram(programId);
  }

  Future<List<WorkoutDay>> getDaysForProgramWeek(String programId, int weekNumber) async {
    return await _db.getWorkoutDaysForProgramWeek(programId, weekNumber);
  }

  Future<void> addWorkoutDay(WorkoutDay day) async {
    await _db.insertWorkoutDay(day);
    notifyListeners();
  }

  Future<void> deleteWorkoutDay(String id) async {
    await _db.deleteWorkoutDay(id);
    notifyListeners();
  }

  Future<void> copyDayToWeek(WorkoutDay day, int targetWeekNumber) async {
    await _db.copyDayToWeek(day, targetWeekNumber);
    notifyListeners();
  }

  Future<void> updateWorkoutDay(WorkoutDay day) async {
    await _db.updateWorkoutDay(day);
    notifyListeners();
  }

  Future<List<ExerciseTarget>> getExercisesForDay(String dayId) async {
    return await _db.getExerciseTargetsForDay(dayId);
  }
  
  Future<void> addExerciseTarget(ExerciseTarget target) async {
    await _db.insertExerciseTarget(target);
    notifyListeners();
  }

  Future<void> deleteExerciseTarget(String id) async {
    await _db.deleteExerciseTarget(id);
    notifyListeners();
  }

  Future<void> updateExerciseTarget(ExerciseTarget target) async {
    await _db.updateExerciseTarget(target);
    notifyListeners();
  }

  Future<void> clearExerciseSetsToday(ExerciseTarget target) async {
    final allSessions = await _db.getAllSessions();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    for (var s in allSessions) {
      if (s.workoutDayId == target.workoutDayId && s.date.toIso8601String().startsWith(todayStr)) {
        final logs = await _db.getSetLogsForSession(s.id);
        final exerciseLogs = logs.where((l) => l.exerciseName == target.name);
        for (var log in exerciseLogs) {
          await _db.deleteSetLog(log.id);
        }
        break;
      }
    }
    notifyListeners();
  }

  Future<void> toggleExerciseCompletion(ExerciseTarget target, bool isCompleted) async {
    final updated = ExerciseTarget(
      id: target.id,
      workoutDayId: target.workoutDayId,
      name: target.name,
      targetSets: target.targetSets,
      targetReps: target.targetReps,
      targetWeight: target.targetWeight,
      restSeconds: target.restSeconds,
      notes: target.notes,
      orderIndex: target.orderIndex,
      isCompleted: isCompleted,
    );
    await _db.updateExerciseTarget(updated);
    notifyListeners();
  }

  // Real-time operations like running the timer and active workout can be managed in their own localized state or here.
}
