import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../providers/workout_provider.dart';
import '../providers/timer_provider.dart';

class WorkoutModeScreen extends StatefulWidget {
  final WorkoutDay day;

  const WorkoutModeScreen({super.key, required this.day});

  @override
  State<WorkoutModeScreen> createState() => _WorkoutModeScreenState();
}

class _WorkoutModeScreenState extends State<WorkoutModeScreen> {
  late Future<List<ExerciseTarget>> _exercisesFuture;
  WorkoutSession? _currentSession;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _exercisesFuture = Future.value([]); // Initialize with empty future
    _initWorkout();
  }

  Future<void> _initWorkout() async {
    final exercises = await context.read<WorkoutProvider>().getExercisesForDay(widget.day.id);
    if (exercises.isNotEmpty) {
      final allSessions = await DatabaseHelper.instance.getAllSessions();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      
      WorkoutSession? session;
      for (var s in allSessions) {
        if (s.workoutDayId == widget.day.id && s.date.toIso8601String().startsWith(todayStr)) {
          session = s;
          break;
        }
      }
      
      if (session == null) {
        session = WorkoutSession(
          id: const Uuid().v4(),
          workoutDayId: widget.day.id,
          date: DateTime.now(),
          durationSeconds: 0, 
        );
        await DatabaseHelper.instance.insertWorkoutSession(session);
      }
      
      if (mounted) {
        setState(() {
          _currentSession = session;
          _exercisesFuture = Future.value(exercises);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _exercisesFuture = Future.value([]);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.day.name.toUpperCase()} - ACTIVE'),
      ),
      body: FutureBuilder<List<ExerciseTarget>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercises = snapshot.data ?? [];
          if (exercises.isEmpty || _currentSession == null) {
            return const Center(
              child: Text('Nessun esercizio impostato.\nAggiungi prima degli esercizi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            );
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final target = exercises[index];
                    return _ActiveExerciseView(
                      target: target,
                      session: _currentSession!,
                      onNextExercise: () {
                        if (index < exercises.length - 1) {
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                      onPrevExercise: () {
                        if (index > 0) {
                          _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveExerciseView extends StatefulWidget {
  final ExerciseTarget target;
  final WorkoutSession session;
  final VoidCallback onNextExercise;
  final VoidCallback onPrevExercise;

  const _ActiveExerciseView({
    required this.target,
    required this.session,
    required this.onNextExercise,
    required this.onPrevExercise,
  });

  @override
  State<_ActiveExerciseView> createState() => _ActiveExerciseViewState();
}

class _ActiveExerciseViewState extends State<_ActiveExerciseView>
    with SingleTickerProviderStateMixin {
  List<SetLog> completedSets = [];
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: widget.target.targetReps.toString());
    _weightController = TextEditingController(text: widget.target.targetWeight.toString());
    _loadCompletedSets();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 8.0, end: 22.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  Future<void> _loadCompletedSets() async {
    final logs = await DatabaseHelper.instance.getSetLogsForSession(widget.session.id);
    if (mounted) {
      setState(() {
        completedSets = logs.where((l) => l.exerciseName == widget.target.name).toList();
      });
    }
  }

  void _deleteSet(SetLog log) async {
    await DatabaseHelper.instance.deleteSetLog(log.id);
    
    if (completedSets.length - 1 < widget.target.targetSets && widget.target.isCompleted) {
      if (mounted) context.read<WorkoutProvider>().toggleExerciseCompletion(widget.target, false);
    }
    _loadCompletedSets();
  }

  void _logSet() async {
    final reps = int.tryParse(_repsController.text) ?? widget.target.targetReps;
    final weight = double.tryParse(_weightController.text) ?? widget.target.targetWeight;

    final log = SetLog(
      id: const Uuid().v4(),
      sessionId: widget.session.id,
      exerciseName: widget.target.name,
      reps: reps,
      weight: weight,
      isCompleted: true,
      timestamp: DateTime.now(),
    );

    await DatabaseHelper.instance.insertSetLog(log);
    
    // Attivazione Timer Globale usando restSeconds personalizzato
    if (mounted) {
      context.read<TimerProvider>().startTimer(widget.target.restSeconds);
      if (completedSets.length + 1 >= widget.target.targetSets) {
        context.read<WorkoutProvider>().toggleExerciseCompletion(widget.target, true);
      }
    }
    
    _loadCompletedSets();
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, size: 32), onPressed: widget.onPrevExercise),
              Expanded(
                child: Text(
                  widget.target.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right, size: 32), onPressed: widget.onNextExercise),
            ],
          ),
          if (widget.target.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Nota: ${widget.target.notes}',
                style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('PROGRESSO TARGET', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Glow animated set counter
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1100),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9800).withOpacity(0.35),
                    blurRadius: _glowAnim.value,
                    spreadRadius: 1,
                  )
                ],
                border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
              ),
              child: Text(
                '${completedSets.length} / ${widget.target.targetSets} SET COMPLETATI',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF9800), fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'KG',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('X', style: TextStyle(fontSize: 24, color: Colors.white54)),
              ),
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'REPS',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF9800).withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6)),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: completedSets.length < widget.target.targetSets ? _logSet : null,
              child: const Text('REGISTRA SET ✓', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 32),
          const Text('SERIE COMPLETATE OGGI', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...completedSets.asMap().entries.map((e) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.black,
                child: Text('${e.key + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text('${e.value.weight} KG x ${e.value.reps} Reps', style: const TextStyle(color: Colors.white)),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => _deleteSet(e.value),
                tooltip: 'Elimina questo Set',
              ),
            );
          }),
        ],
      ),
    );
  }
}
