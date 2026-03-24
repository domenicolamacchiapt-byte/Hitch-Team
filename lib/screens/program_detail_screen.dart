import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/workout_provider.dart';
import 'workout_mode_screen.dart';

class ProgramDetailScreen extends StatelessWidget {
  final Program program;
  final bool isAdmin;

  const ProgramDetailScreen({super.key, required this.program, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: program.weeksCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text(program.name.toUpperCase()),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: const Color(0xFFFF9800),
            labelColor: const Color(0xFFFF9800),
            unselectedLabelColor: Colors.white54,
            tabs: List.generate(
                program.weeksCount, (index) => Tab(text: 'SETTIMANA ${index + 1}')),
          ),
        ),
        body: TabBarView(
          children: List.generate(program.weeksCount, (index) {
            return _WeekView(program: program, weekNumber: index + 1, isAdmin: isAdmin);
          }),
        ),
      ),
    );
  }
}

class _WeekView extends StatefulWidget {
  final Program program;
  final int weekNumber;
  final bool isAdmin;

  const _WeekView({required this.program, required this.weekNumber, required this.isAdmin});

  @override
  State<_WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<_WeekView> {
  late Future<List<WorkoutDay>> _daysFuture;

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  void _loadDays() {
    _daysFuture = context
        .read<WorkoutProvider>()
        .getDaysForProgramWeek(widget.program.id, widget.weekNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<WorkoutDay>>(
        future: _daysFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final days = snapshot.data ?? [];
          if (days.isEmpty) {
            return const Center(
              child: Text(
                'Nessuna giornata di allenamento.\nAggiungine una con il tasto +',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          if (widget.isAdmin) {
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: days.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final reordered = List<WorkoutDay>.from(days);
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                // Persist new order_index for each day
                final db = context.read<WorkoutProvider>();
                for (int i = 0; i < reordered.length; i++) {
                  final updated = WorkoutDay(
                    id: reordered[i].id,
                    programId: reordered[i].programId,
                    name: reordered[i].name,
                    weekNumber: reordered[i].weekNumber,
                    orderIndex: i,
                  );
                  await db.updateWorkoutDay(updated);
                }
                setState(() => _loadDays());
              },
              itemBuilder: (context, index) {
                final day = days[index];
                return Material(
                  key: Key(day.id),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.drag_handle, color: Colors.white38),
                      ),
                      Expanded(
                        child: _DayCard(
                          day: day,
                          isAdmin: widget.isAdmin,
                          onRefresh: () => setState(() { _loadDays(); }),
                          program: widget.program,
                          currentWeekNumber: widget.weekNumber,
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text('Elimina Giorno', style: TextStyle(color: Colors.white)),
                                content: Text('Vuoi eliminare "${day.name}" e tutti i suoi esercizi?', style: const TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA', style: TextStyle(color: Colors.white54))),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    child: const Text('ELIMINA'),
                                  ),
                                ],
                              ),
                            ) ?? false;
                            if (confirm && context.mounted) {
                              await context.read<WorkoutProvider>().deleteWorkoutDay(day.id);
                              setState(() => _loadDays());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          // Guest: plain non-reorderable list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return _DayCard(
                day: day,
                isAdmin: false,
                onRefresh: () => setState(() { _loadDays(); }),
                program: widget.program,
                currentWeekNumber: widget.weekNumber,
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isAdmin ? FloatingActionButton(
        onPressed: () => _showAddDayDialog(context),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  void _showAddDayDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Nuovo Giorno', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nome (es. GIORNO 1)',
              hintStyle: TextStyle(color: Colors.white54),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF9800)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ANNULLA', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newDay = WorkoutDay(
                    id: const Uuid().v4(),
                    programId: widget.program.id,
                    name: nameController.text.trim(),
                    orderIndex: (DateTime.now().millisecondsSinceEpoch / 1000).round(),
                    weekNumber: widget.weekNumber,
                  );
                  await context.read<WorkoutProvider>().addWorkoutDay(newDay);
                  if (mounted) {
                    setState(() { _loadDays(); });
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('SALVA'),
            ),
          ],
        );
      },
    );
  }
}

class _DayCard extends StatefulWidget {
  final WorkoutDay day;
  final bool isAdmin;
  final VoidCallback onRefresh;
  final VoidCallback? onDelete;
  final Program? program;
  final int currentWeekNumber;

  const _DayCard({
    required this.day,
    required this.isAdmin,
    required this.onRefresh,
    this.onDelete,
    this.program,
    this.currentWeekNumber = 1,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  late Future<List<ExerciseTarget>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    _exercisesFuture = context.read<WorkoutProvider>().getExercisesForDay(widget.day.id);
  }

  void _showCopyDayDialog(BuildContext context) {
    final program = widget.program;
    if (program == null) return;
    final weeks = List.generate(program.weeksCount, (i) => i + 1)
        .where((w) => w != widget.currentWeekNumber)
        .toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Copia in Settimana', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: weeks.map((w) => ListTile(
            title: Text('Settimana $w', style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF9800), size: 16),
            onTap: () async {
              Navigator.pop(ctx);
              await context.read<WorkoutProvider>().copyDayToWeek(widget.day, w);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${widget.day.name}" copiato nella Settimana $w!'), backgroundColor: Colors.green),
                );
                widget.onRefresh();
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutModeScreen(day: widget.day),
                        ),
                      );
                      setState(() { _loadExercises(); });
                    },
                    child: Text(
                      widget.day.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (widget.isAdmin) IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                  onPressed: () => _showEditDayDialog(context),
                  tooltip: 'Modifica Giorno',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                if (widget.onDelete != null) ...
                [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: widget.onDelete,
                    tooltip: 'Elimina Giorno',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
                if (widget.isAdmin && widget.program != null && widget.program!.weeksCount > 1) ...
                [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, color: Colors.white54, size: 20),
                    tooltip: 'Copia in altra settimana',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showCopyDayDialog(context),
                  ),
                ],
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: Color(0xFFFF9800), size: 32),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutModeScreen(day: widget.day),
                      ),
                    );
                    setState(() { _loadExercises(); });
                  },
                  tooltip: 'Inizia Workout',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            FutureBuilder<List<ExerciseTarget>>(
              future: _exercisesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
                }
                final exercises = snapshot.data ?? [];
                if (exercises.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Text('Nessun esercizio. Tocca + per aggiungerne uno.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: exercises.map((e) => InkWell(
                    onTap: widget.isAdmin || e.isCompleted ? () => _showEditExerciseDialog(context, e) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            e.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            color: e.isCompleted ? const Color(0xFFFF9800) : Colors.white24,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${e.name} (${e.targetSets}x${e.targetReps} @ ${e.targetWeight}kg) [Ric: ${e.restSeconds}s]', 
                              style: TextStyle(
                                color: e.isCompleted ? Colors.white30 : Colors.white70,
                                fontSize: 15,
                                decoration: e.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
            if (widget.isAdmin) const SizedBox(height: 12),
            if (widget.isAdmin) Center(
              child: TextButton.icon(
                onPressed: () => _showAddExerciseDialog(context),
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF9800)),
                label: const Text('Aggiungi Esercizio', style: TextStyle(color: Color(0xFFFF9800))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDayDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.day.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Modifica Giorno', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Nome Giorno', labelStyle: TextStyle(color: Colors.white54)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await context.read<WorkoutProvider>().deleteWorkoutDay(widget.day.id);
                if (mounted) {
                  widget.onRefresh();
                  Navigator.pop(context);
                }
              },
              child: const Text('ELIMINA', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ANNULLA', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final updatedDay = WorkoutDay(
                    id: widget.day.id,
                    programId: widget.day.programId,
                    name: nameController.text.trim(),
                    orderIndex: widget.day.orderIndex,
                    weekNumber: widget.day.weekNumber,
                  );
                  await context.read<WorkoutProvider>().updateWorkoutDay(updatedDay);
                  if (mounted) {
                    widget.onRefresh();
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('SALVA'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    _showExerciseFormDialog(context, null);
  }

  void _showEditExerciseDialog(BuildContext context, ExerciseTarget exercise) {
    _showExerciseFormDialog(context, exercise);
  }

  void _showExerciseFormDialog(BuildContext context, ExerciseTarget? existingExercise) {
    final isEditing = existingExercise != null;
    final nameController = TextEditingController(text: isEditing ? existingExercise.name : '');
    final setsController = TextEditingController(text: isEditing ? existingExercise.targetSets.toString() : '4');
    final repsController = TextEditingController(text: isEditing ? existingExercise.targetReps.toString() : '10');
    final weightController = TextEditingController(text: isEditing ? existingExercise.targetWeight.toString() : '20');
    final restController = TextEditingController(text: isEditing ? existingExercise.restSeconds.toString() : '90');
    final notesController = TextEditingController(text: isEditing ? existingExercise.notes : '');
    
    final dictionary = context.read<WorkoutProvider>().dictionary;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(isEditing ? 'Modifica Esercizio' : 'Nuovo Esercizio', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: nameController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return dictionary;
                    }
                    return dictionary.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    nameController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    controller.addListener(() { nameController.text = controller.text; });
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nome Esercizio (digita o scegli)',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 260),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option, style: const TextStyle(color: Colors.white)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: setsController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Sets', labelStyle: TextStyle(color: Colors.white54)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: repsController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Reps', labelStyle: TextStyle(color: Colors.white54)))),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weightController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Kg', labelStyle: TextStyle(color: Colors.white54)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: restController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Recupero (s)', labelStyle: TextStyle(color: Colors.white54)))),
                  ],
                ),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Note del Coach', labelStyle: TextStyle(color: Colors.white54)),
                )
              ],
            ),
          ),
          actions: [
            if (isEditing) TextButton(
              onPressed: () async {
                if (!widget.isAdmin && existingExercise.isCompleted) return;
                final nextState = !existingExercise.isCompleted;
                await context.read<WorkoutProvider>().toggleExerciseCompletion(existingExercise, nextState);
                if (!nextState) {
                  if (context.mounted) await context.read<WorkoutProvider>().clearExerciseSetsToday(existingExercise);
                }
                if (mounted) {
                  setState(() { _loadExercises(); });
                  Navigator.pop(context);
                }
              },
              child: Text(
                existingExercise.isCompleted ? 'SEGNA DA FARE' : 'SEGNA FATTO', 
                style: const TextStyle(color: Colors.white54)
              ),
            ),
            if (isEditing && widget.isAdmin) TextButton(
              onPressed: () async {
                await context.read<WorkoutProvider>().deleteExerciseTarget(existingExercise.id);
                if (mounted) {
                  setState(() { _loadExercises(); });
                  Navigator.pop(context);
                }
              },
              child: const Text('ELIMINA', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ANNULLA', style: TextStyle(color: Colors.white70)),
            ),
            if (widget.isAdmin) ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final provider = context.read<WorkoutProvider>();
                  final targetSets = int.tryParse(setsController.text) ?? 4;
                  final targetReps = int.tryParse(repsController.text) ?? 10;
                  final targetWeight = double.tryParse(weightController.text) ?? 0.0;
                  final restSeconds = int.tryParse(restController.text) ?? 90;
                  
                  final exerciseName = nameController.text.trim();
                  await provider.addToDictionary(exerciseName);
                  
                  if (isEditing) {
                    final updatedEx = ExerciseTarget(
                      id: existingExercise.id,
                      workoutDayId: existingExercise.workoutDayId,
                      name: nameController.text.trim(),
                      targetSets: targetSets,
                      targetReps: targetReps,
                      targetWeight: targetWeight,
                      restSeconds: restSeconds,
                      notes: notesController.text.trim(),
                      orderIndex: existingExercise.orderIndex,
                      isCompleted: existingExercise.isCompleted,
                    );
                    await provider.updateExerciseTarget(updatedEx);
                  } else {
                    final newEx = ExerciseTarget(
                      id: const Uuid().v4(),
                      workoutDayId: widget.day.id,
                      name: nameController.text.trim(),
                      targetSets: targetSets,
                      targetReps: targetReps,
                      targetWeight: targetWeight,
                      restSeconds: restSeconds,
                      notes: notesController.text.trim(),
                      orderIndex: (DateTime.now().millisecondsSinceEpoch / 1000).round(),
                    );
                    await provider.addExerciseTarget(newEx);
                  }
                  if (mounted) {
                    setState(() { _loadExercises(); });
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('SALVA'),
            ),
          ],
        );
      },
    );
  }
}
