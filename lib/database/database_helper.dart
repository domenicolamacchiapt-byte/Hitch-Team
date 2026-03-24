import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final _supabase = Supabase.instance.client;

  DatabaseHelper._init();

  String get _userId => _supabase.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> getClients() async {
    final response = await _supabase.from('profiles').select().eq('role', 'client').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- CRUD: Programs ---
  Future<void> insertProgram(Program program, {String? targetUserId}) async {
    final map = program.toMap();
    map['user_id'] = targetUserId ?? _userId;
    await _supabase.from('programs').upsert(map);
  }

  Future<List<Program>> getPrograms({String? specificUserId}) async {
    final uid = specificUserId ?? _userId;
    final response = await _supabase.from('programs').select().eq('user_id', uid).order('created_at', ascending: false);
    final maps = List<Map<String, dynamic>>.from(response);
    return maps.map((map) => Program.fromMap(map)).toList();
  }

  Future<void> updateProgram(Program program) async {
    await _supabase.from('programs').update(program.toMap()).eq('id', program.id);
  }

  Future<void> deleteProgram(String id) async {
    await _supabase.from('programs').delete().eq('id', id);
  }

  // --- CRUD: WorkoutDays ---
  Future<void> insertWorkoutDay(WorkoutDay day) async {
    await _supabase.from('workout_days').upsert(day.toMap());
  }

  Future<void> updateWorkoutDay(WorkoutDay day) async {
    await _supabase.from('workout_days').update(day.toMap()).eq('id', day.id);
  }

  Future<List<WorkoutDay>> getWorkoutDaysForProgram(String programId) async {
    final response = await _supabase.from('workout_days').select().eq('program_id', programId).order('order_index', ascending: true);
    final maps = List<Map<String, dynamic>>.from(response);
    return maps.map((map) => WorkoutDay.fromMap(map)).toList();
  }

  Future<List<WorkoutDay>> getWorkoutDaysForProgramWeek(String programId, int weekNumber) async {
    final response = await _supabase.from('workout_days').select().eq('program_id', programId).eq('week_number', weekNumber).order('order_index', ascending: true);
    final maps = List<Map<String, dynamic>>.from(response);
    return maps.map((map) => WorkoutDay.fromMap(map)).toList();
  }

  Future<void> deleteWorkoutDay(String id) async {
    await _supabase.from('workout_days').delete().eq('id', id);
  }

  Future<void> copyDayToWeek(WorkoutDay sourceDay, int targetWeekNumber) async {
    // Create new day in target week
    final now = DateTime.now();
    final newDayId = '${now.millisecondsSinceEpoch ~/ 1000}-copy';
    final newDay = WorkoutDay(
      id: newDayId,
      programId: sourceDay.programId,
      name: sourceDay.name,
      weekNumber: targetWeekNumber,
      orderIndex: now.millisecondsSinceEpoch ~/ 1000,
    );
    await _supabase.from('workout_days').upsert(newDay.toMap());

    // Copy all exercises
    final exercises = await getExerciseTargetsForDay(sourceDay.id);
    for (int i = 0; i < exercises.length; i++) {
      final e = exercises[i];
      final newExercise = ExerciseTarget(
        id: '${now.millisecondsSinceEpoch ~/ 1000}-ex-$i',
        workoutDayId: newDayId,
        name: e.name,
        targetSets: e.targetSets,
        targetReps: e.targetReps,
        targetWeight: e.targetWeight,
        restSeconds: e.restSeconds,
        notes: e.notes,
        orderIndex: e.orderIndex,
        isCompleted: false,
      );
      await _supabase.from('exercises').upsert(newExercise.toMap());
    }
  }

  // --- CRUD: ExerciseTargets ---
  Future<void> insertExerciseTarget(ExerciseTarget target) async {
    await _supabase.from('exercises').upsert(target.toMap());
  }

  Future<void> updateExerciseTarget(ExerciseTarget target) async {
    await _supabase.from('exercises').update(target.toMap()).eq('id', target.id);
  }

  Future<List<ExerciseTarget>> getExerciseTargetsForDay(String workoutDayId) async {
    final response = await _supabase.from('exercises').select().eq('workout_day_id', workoutDayId).order('order_index', ascending: true);
    final maps = List<Map<String, dynamic>>.from(response);
    return maps.map((map) => ExerciseTarget.fromMap(map)).toList();
  }

  Future<void> deleteExerciseTarget(String id) async {
    await _supabase.from('exercises').delete().eq('id', id);
  }

  // --- CRUD: WorkoutSessions & SetLogs ---
  Future<void> insertWorkoutSession(WorkoutSession session) async {
    final map = session.toMap();
    map['user_id'] = _userId;
    await _supabase.from('workout_sessions').upsert(map);
  }

  Future<void> insertSetLog(SetLog log) async {
    final map = log.toMap();
    map['user_id'] = _userId;
    await _supabase.from('set_logs').upsert(map);
  }

  Future<void> deleteSetLog(String id) async {
    await _supabase.from('set_logs').delete().eq('id', id);
  }
  
  Future<List<SetLog>> getSetLogsForSession(String sessionId) async {
    final response = await _supabase.from('set_logs').select().eq('session_id', sessionId).order('timestamp', ascending: true);
    final maps = List<Map<String, dynamic>>.from(response);
    return maps.map((map) => SetLog.fromMap(map)).toList();
  }

  Future<List<SetLog>> getSetLogsForExercise(String exerciseName) async {
    final response = await _supabase.from('set_logs').select().eq('exercise_name', exerciseName).eq('user_id', _userId).order('timestamp', ascending: true);
    final maps = List<Map<String, dynamic>>.from(response);
    return maps.map((map) => SetLog.fromMap(map)).toList();
  }

  Future<List<WorkoutSession>> getAllSessions() async {
    final response = await _supabase.from('workout_sessions').select().eq('user_id', _userId).order('date', ascending: false);
    final maps = List<Map<String, dynamic>>.from(response);
    return maps.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  // --- CRUD: Dictionary ---
  Future<void> insertDictionaryExercise(String name) async {
    await _supabase.from('exercise_dictionary').upsert({'name': name});
  }

  Future<void> updateDictionaryExercise(String oldName, String newName) async {
    await _supabase.from('exercise_dictionary').update({'name': newName}).eq('name', oldName);
  }

  Future<void> deleteDictionaryExercise(String name) async {
    await _supabase.from('exercise_dictionary').delete().eq('name', name);
  }

  Future<List<String>> getDictionaryExercises() async {
    final maps = await _supabase.from('exercise_dictionary').select('name').order('name', ascending: true);
    return maps.map((e) => e['name'] as String).toList();
  }
}
