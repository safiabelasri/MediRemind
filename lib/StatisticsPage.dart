import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'AddMedicinePage.dart';
import 'FirebaseService.dart';
// Assure-toi d’avoir ce fichier ou adapte l’import

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Medication>> _medicationsFuture;
  String _timeRange = '7 jours';
  final List<String> _timeRanges = ['7 jours', '30 jours', '90 jours', 'Tout'];

  @override
  void initState() {
    super.initState();
    _medicationsFuture = _firebaseService.getAllMedications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiques'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: FutureBuilder<List<Medication>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final medications = snapshot.data ?? [];
          return _buildStatisticsContent(medications);
        },
      ),
    );
  }

  Widget _buildStatisticsContent(List<Medication> medications) {
    final filteredMeds = _filterMedicationsByTimeRange(medications);
    final confirmedCount = filteredMeds.where((m) => m.confirmed).length;
    final pendingCount = filteredMeds.length - confirmedCount;
    final confirmationRate =
    filteredMeds.isNotEmpty ? (confirmedCount / filteredMeds.length * 100).round() : 0;
    final typeStats = _calculateTypeStatistics(filteredMeds);
    final timeStats = _calculateTimeStatistics(filteredMeds);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRangeSelector(),
          SizedBox(height: 20),
          _buildSummaryCard(confirmedCount, pendingCount, confirmationRate),
          SizedBox(height: 20),
          _buildPieChart(confirmedCount, pendingCount),
          SizedBox(height: 20),
          _buildTypeStatistics(typeStats),
          SizedBox(height: 20),
          _buildTimeStatistics(timeStats),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _timeRange,
          isExpanded: true,
          items: _timeRanges.map((range) {
            return DropdownMenuItem(
              value: range,
              child: Text('Période: $range'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _timeRange = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int confirmed, int pending, int rate) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', confirmed + pending, Icons.medication),
                _buildStatItem('Pris', confirmed, Icons.check_circle, Colors.green),
                _buildStatItem('En attente', pending, Icons.access_time, Colors.orange),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: Colors.grey[200],
              color: Colors.blueAccent,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            SizedBox(height: 8),
            Text(
              'Taux de prise: $rate%',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blueAccent, size: 30),
        SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPieChart(int confirmed, int pending) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition des prises',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 250,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  PieSeries<MapEntry<String, int>, String>(
                    dataSource: [
                      MapEntry('Pris', confirmed),
                      MapEntry('En attente', pending),
                    ],
                    xValueMapper: (entry, _) => entry.key,
                    yValueMapper: (entry, _) => entry.value,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                      textStyle: TextStyle(color: Colors.white),
                    ),
                    pointColorMapper: (entry, _) =>
                    entry.key == 'Pris' ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeStatistics(Map<String, int> typeStats) {
    final sortedTypes = typeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Médicaments par type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Column(
              children: sortedTypes.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: entry.value / sortedTypes.first.value,
                          backgroundColor: Colors.grey[200],
                          color: Colors.blueAccent,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(entry.value.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTimeStatistics(Map<String, int> timeStats) {
    final hours = List.generate(24, (index) => index.toString().padLeft(2, '0'));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prise par heure de la journée',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(labelPlacement: LabelPlacement.onTicks),

              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Medication> _filterMedicationsByTimeRange(List<Medication> medications) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_timeRange) {
      case '7 jours':
        startDate = now.subtract(Duration(days: 7));
        break;
      case '30 jours':
        startDate = now.subtract(Duration(days: 30));
        break;
      case '90 jours':
        startDate = now.subtract(Duration(days: 90));
        break;
      default:
        return medications;
    }

    return medications.where((m) => m.time.isAfter(startDate)).toList();
  }

  Map<String, int> _calculateTypeStatistics(List<Medication> medications) {
    final Map<String, int> typeCount = {};
    for (var med in medications) {
      final type = med.type ?? 'Inconnu';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    return typeCount;
  }

  Map<String, int> _calculateTimeStatistics(List<Medication> medications) {
    final Map<String, int> timeStats = {};
    for (var med in medications) {
      final hour = med.time.hour.toString().padLeft(2, '0');
      timeStats[hour] = (timeStats[hour] ?? 0) + 1;
    }
    return timeStats;
  }
}
