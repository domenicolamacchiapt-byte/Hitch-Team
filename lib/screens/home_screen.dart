import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import 'program_detail_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'dictionary_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wp = context.watch<WorkoutProvider>();

    if (auth.isAdmin && wp.activeClientId == null) {
      if (!wp.clientsLoaded) Future.microtask(() => wp.loadClients());
      return _buildAdminClientsDashboard(context, wp);
    }
    
    if (!auth.isAdmin && !wp.programsLoaded) {
      Future.microtask(() => wp.loadPrograms());
    }

    final isClientViewForAdmin = auth.isAdmin && wp.activeClientId != null;

    return Scaffold(
      appBar: AppBar(
        leading: isClientViewForAdmin 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => wp.clearActiveClient()) 
          : null,
        title: Text(isClientViewForAdmin ? 'SCHEDE CLIENTE' : 'LE TUE SCHEDE'),
        actions: [
          if (!isClientViewForAdmin) IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () => context.read<AuthProvider>().signOut(),
            tooltip: 'Logout',
          ),
          if (!isClientViewForAdmin) IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFFFF9800)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            tooltip: 'Profilo',
          ),
          if (auth.isAdmin) IconButton(
            icon: const Icon(Icons.fitness_center, color: Color(0xFFFF9800)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DictionaryScreen()),
              );
            },
            tooltip: 'Database Esercizi',
          ),
          IconButton(
            icon: const Icon(Icons.show_chart, color: Color(0xFFFF9800)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            tooltip: 'Storico & Analisi',
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          final programs = provider.programs;

          if (programs.isEmpty) {
            if (!auth.isAdmin) {
              return const Center(child: Text('Il tuo Coach non ti ha ancora assegnato schede.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)));
            }
            return const Center(
              child: Text(
                'Nessun programma trovato.\nPremi + per crearne uno nuovo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return _StaggerFade(
                delay: Duration(milliseconds: index * 60),
                child: Dismissible(
                  key: Key(program.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: auth.isAdmin ? DismissDirection.endToStart : DismissDirection.none,
                  onDismissed: (direction) {
                    context.read<WorkoutProvider>().deleteProgram(program.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${program.name} eliminato')));
                  },
                  child: _ProgramCard(
                    program: program,
                    isAdmin: auth.isAdmin,
                    onEdit: () => _showProgramFormDialog(context, program),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: auth.isAdmin ? FloatingActionButton(
        onPressed: () => _showProgramFormDialog(context, null),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildAdminClientsDashboard(BuildContext context, WorkoutProvider wp) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PANNELLO COACH'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFFFF9800)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            tooltip: 'Profilo',
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => wp.loadClients(force: true)),
          IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.redAccent), onPressed: () => context.read<AuthProvider>().signOut()),
        ],
      ),
      body: wp.clients.isEmpty
          ? const Center(child: Text('Nessun cliente registrato', style: TextStyle(color: Colors.white70)))
          : ListView.builder(
              itemCount: wp.clients.length,
              itemBuilder: (context, i) {
                final client = wp.clients[i];
                final fn = client['first_name'] ?? '';
                final ln = client['last_name'] ?? '';
                final fullName = '${fn} ${ln}'.trim();
                final displayName = fullName.isNotEmpty ? fullName : (client['email'] ?? 'Sconosciuto');
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF9800),
                    child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(client['email'] ?? '', style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_outline, color: Color(0xFFFF9800)),
                        tooltip: 'Scheda Profilo',
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ProfileScreen(clientData: client),
                        )),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                    ],
                  ),
                  onTap: () => wp.loadPrograms(clientId: client['id']),
                );
              },
            ),
    );
  }

  void _showProgramFormDialog(BuildContext context, Program? existingProgram) {
    final isEditing = existingProgram != null;
    final TextEditingController nameController = TextEditingController(text: isEditing ? existingProgram.name : '');
    final TextEditingController weeksController = TextEditingController(text: isEditing ? existingProgram.weeksCount.toString() : '4');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(isEditing ? 'Modifica Programma' : 'Nuovo Programma', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nome (es. Mese 1 - Ottobre)',
                  hintStyle: TextStyle(color: Colors.white54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF9800)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weeksController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Numero di Settimane',
                  labelStyle: TextStyle(color: Colors.white54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF9800)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (isEditing) TextButton(
              onPressed: () async {
                await context.read<WorkoutProvider>().deleteProgram(existingProgram.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ELIMINA', style: TextStyle(color: Colors.redAccent)),
            ),
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
                  final weeksCount = int.tryParse(weeksController.text) ?? 4;
                  if (isEditing) {
                    final updatedProgram = Program(
                      id: existingProgram.id,
                      name: nameController.text.trim(),
                      startDate: existingProgram.startDate,
                      endDate: existingProgram.endDate,
                      weeksCount: weeksCount,
                    );
                    await context.read<WorkoutProvider>().updateProgram(updatedProgram);
                  } else {
                    final newProgram = Program(
                      id: const Uuid().v4(),
                      name: nameController.text.trim(),
                      startDate: DateTime.now(),
                      weeksCount: weeksCount,
                    );
                    await context.read<WorkoutProvider>().addProgram(newProgram);
                  }
                  if (context.mounted) Navigator.pop(context);
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

class _ProgramCard extends StatelessWidget {
  final Program program;
  final bool isAdmin;
  final VoidCallback onEdit;

  const _ProgramCard({required this.program, required this.isAdmin, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final initial = program.name.isNotEmpty ? program.name[0].toUpperCase() : 'P';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProgramDetailScreen(program: program, isAdmin: isAdmin)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Orange accent bar on left
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // Avatar with initial
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFF9800).withOpacity(0.15),
                        radius: 24,
                        child: Text(initial, style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              program.name.toUpperCase(),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4), width: 0.8),
                                  ),
                                  child: Text('${program.weeksCount} SETT.', style: const TextStyle(color: Color(0xFFFF9800), fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM yyyy').format(program.startDate),
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (isAdmin) IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white38, size: 20),
                            onPressed: onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          if (isAdmin) const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF9800), size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Staggered fade-slide animation wrapper
class _StaggerFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _StaggerFade({required this.child, required this.delay});
  @override
  State<_StaggerFade> createState() => _StaggerFadeState();
}

class _StaggerFadeState extends State<_StaggerFade> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
