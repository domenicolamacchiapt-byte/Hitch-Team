import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SetLog> _allLogs = [];
  List<String> _exerciseNames = [];
  String? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await DatabaseHelper.instance.getAllSessions();
    final Set<String> names = {};
    for (var session in sessions) {
      final logs = await DatabaseHelper.instance.getSetLogsForSession(session.id);
      for (var log in logs) {
        names.add(log.exerciseName);
      }
    }
    
    if (mounted) {
      setState(() {
        _exerciseNames = names.toList()..sort();
        if (_exerciseNames.isNotEmpty) {
          _selectedExercise = _exerciseNames.first;
          _loadExerciseHistory(_selectedExercise!);
        }
      });
    }
  }

  Future<void> _loadExerciseHistory(String exerciseName) async {
    final logs = await DatabaseHelper.instance.getSetLogsForExercise(exerciseName);
    if (mounted) {
      setState(() {
        _allLogs = logs;
      });
    }
  }

  Map<String, double> _calculateVolumeData() {
    final Map<String, double> volumeByDate = {};
    final formatter = DateFormat('yyyy-MM-dd');
    
    for (var log in _allLogs) {
      final dateStr = formatter.format(log.timestamp);
      final volume = log.reps * log.weight;
      volumeByDate[dateStr] = (volumeByDate[dateStr] ?? 0) + volume;
    }
    return volumeByDate;
  }

  double _calculatePR() {
    double pr = 0;
    for (var log in _allLogs) {
      if (log.weight > pr) pr = log.weight;
    }
    return pr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STORICO E ANALISI'),
      ),
      body: _exerciseNames.isEmpty 
        ? const Center(child: Text('Nessun dato storico disponibile.\\nCompleta prima un allenamento!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedExercise,
                  decoration: InputDecoration(
                    labelText: 'Seleziona Esercizio',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  items: _exerciseNames.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(color: Colors.white)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedExercise = val;
                        _loadExerciseHistory(val);
                      });
                    }
                  },
                ),
              ),
              if (_selectedExercise != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('PERSONAL RECORD: ', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(20)),
                        child: Text('${_calculatePR()} KG', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('ANDAMENTO VOLUME (KG)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24.0, left: 8.0),
                    child: _buildChart(),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('ULTIME SESSIONI', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allLogs.length,
                    itemBuilder: (context, index) {
                      final log = _allLogs[_allLogs.length - 1 - index];
                      final formatter = DateFormat('dd MMM yyyy - HH:mm');
                      return Card(
                        color: Theme.of(context).cardColor,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${log.weight} KG x ${log.reps} Reps', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(formatter.format(log.timestamp), style: const TextStyle(color: Colors.white54)),
                          trailing: const Icon(Icons.fitness_center, color: Color(0xFFFF9800)),
                        ),
                      );
                    },
                  ),
                ),
              ]
            ],
          ),
    );
  }

  Widget _buildChart() {
    final volumeData = _calculateVolumeData();
    if (volumeData.isEmpty) {
      return const Center(child: Text('Dati non sufficienti per il grafico', style: TextStyle(color: Colors.white54)));
    }

    final sortedKeys = volumeData.keys.toList()..sort();
    final spots = <FlSpot>[];
    
    double maxY = 0;
    for (int i = 0; i < sortedKeys.length; i++) {
      final y = volumeData[sortedKeys[i]]!;
      if (y > maxY) maxY = y;
      spots.add(FlSpot(i.toDouble(), y));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  final date = DateTime.parse(sortedKeys[value.toInt()]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${date.day}/${date.month}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedKeys.length - 1).toDouble() > 0 ? (sortedKeys.length - 1).toDouble() : 1,
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFFF9800),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF9800).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
