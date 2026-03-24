class Program {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final int weeksCount;

  Program({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.weeksCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': startDate.toIso8601String(),
      'updated_at': endDate?.toIso8601String(),
      'weeks_count': weeksCount,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['created_at']),
      endDate: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      weeksCount: map['weeks_count'] ?? 1,
    );
  }
}

class WorkoutDay {
  final String id;
  final String programId;
  final String name;
  final int orderIndex;
  final int weekNumber;

  WorkoutDay({
    required this.id,
    required this.programId,
    required this.name,
    required this.orderIndex,
    required this.weekNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'program_id': programId,
      'name': name,
      'order_index': orderIndex,
      'week_number': weekNumber,
    };
  }

  factory WorkoutDay.fromMap(Map<String, dynamic> map) {
    return WorkoutDay(
      id: map['id'],
      programId: map['program_id'],
      name: map['name'],
      orderIndex: map['order_index'] ?? 0,
      weekNumber: map['week_number'] ?? 1,
    );
  }
}

class ExerciseTarget {
  final String id;
  final String workoutDayId;
  final String name;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restSeconds;
  final String notes;
  final int orderIndex;
  final bool isCompleted;

  ExerciseTarget({
    required this.id,
    required this.workoutDayId,
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.restSeconds,
    required this.notes,
    required this.orderIndex,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_day_id': workoutDayId,
      'name': name,
      'sets': targetSets,
      'reps': targetReps,
      'weight': targetWeight,
      'rest_seconds': restSeconds,
      'notes': notes,
      'order_index': orderIndex,
      'is_completed': isCompleted,
    };
  }

  factory ExerciseTarget.fromMap(Map<String, dynamic> map) {
    return ExerciseTarget(
      id: map['id'],
      workoutDayId: map['workout_day_id'],
      name: map['name'],
      targetSets: map['sets'],
      targetReps: map['reps'],
      targetWeight: (map['weight'] as num).toDouble(),
      restSeconds: map['rest_seconds'] ?? 90,
      notes: map['notes'] ?? '',
      orderIndex: map['order_index'] ?? 0,
      isCompleted: map['is_completed'] == true,
    );
  }
}

class WorkoutSession {
  final String id;
  final String workoutDayId;
  final DateTime date;
  final int durationSeconds;

  WorkoutSession({
    required this.id,
    required this.workoutDayId,
    required this.date,
    required this.durationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_day_id': workoutDayId,
      'date': date.toIso8601String(),
      'duration_seconds': durationSeconds,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'],
      workoutDayId: map['workout_day_id'],
      date: DateTime.parse(map['date']),
      durationSeconds: map['duration_seconds'],
    );
  }
}

class SetLog {
  final String id;
  final String sessionId;
  final String exerciseName;
  final int reps;
  final double weight;
  final bool isCompleted;
  final DateTime timestamp;

  SetLog({
    required this.id,
    required this.sessionId,
    required this.exerciseName,
    required this.reps,
    required this.weight,
    required this.isCompleted,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_name': exerciseName,
      'reps': reps,
      'weight': weight,
      'is_completed': isCompleted,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      id: map['id'],
      sessionId: map['session_id'],
      exerciseName: map['exercise_name'],
      reps: map['reps'],
      weight: (map['weight'] as num).toDouble(),
      isCompleted: map['is_completed'] == true,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
