import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import 'program_detail_screen.dart';
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
              return Dismissible(
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
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => wp.loadClients(force: true)),
          IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.redAccent), onPressed: () => context.read<AuthProvider>().signOut()),
        ],
      ),
      body: wp.clients.isEmpty ? const Center(child: Text('Nessun cliente registrato', style: TextStyle(color: Colors.white70))) : ListView.builder(
        itemCount: wp.clients.length,
        itemBuilder: (context, i) {
          final client = wp.clients[i];
          return ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFFF9800), child: Icon(Icons.person, color: Colors.black)),
            title: Text(client['email'] ?? 'Sconosciuto', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Iscritto il ${client['created_at'].toString().split('T')[0]}', style: const TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () => wp.loadPrograms(clientId: client['id']),
          );
        }
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramDetailScreen(program: program, isAdmin: isAdmin),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Iniziato il: ${DateFormat('dd MMM yyyy').format(program.startDate)} (${program.weeksCount} sett.)',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isAdmin) IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white54, size: 24),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (isAdmin) const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF9800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
