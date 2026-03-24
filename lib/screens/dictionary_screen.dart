import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DATABASE ESERCIZI'),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          final dict = provider.dictionary;
          
          if (dict.isEmpty) {
            return const Center(
              child: Text(
                'Nessun esercizio nel database.\nAggiungine uno col tasto +.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dict.length,
            itemBuilder: (context, index) {
              final name = dict[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white54),
                        onPressed: () => _showFormDialog(context, name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmDialog(context, name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Elimina Esercizio', style: TextStyle(color: Colors.white)),
        content: Text('Sei sicuro di voler eliminare "$name" dal dizionario?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLA', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              context.read<WorkoutProvider>().removeFromDictionary(name);
              Navigator.pop(context);
            },
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, String? existingName) {
    final isEditing = existingName != null;
    final controller = TextEditingController(text: existingName ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(isEditing ? 'Modifica Esercizio' : 'Nuovo Esercizio', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nome Esercizio',
            labelStyle: TextStyle(color: Colors.white54),
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                if (isEditing) {
                  context.read<WorkoutProvider>().updateInDictionary(existingName, newName);
                } else {
                  context.read<WorkoutProvider>().addToDictionary(newName);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('SALVA'),
          ),
        ],
      ),
    );
  }
}
