import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater l'heure

class MedicationDetailPage extends StatelessWidget {
  final String medicationId;
  final String name;
  final int dosage;
  final String type;
  final String interval;
  final DateTime time;
  final String assistant;

  // Constructeur pour initialiser la page avec les informations du médicament
  MedicationDetailPage({
    required this.medicationId,
    required this.name,
    required this.dosage,
    required this.type,
    required this.interval,
    required this.time,
    required this.assistant,
  });

  // Simuler la modification des informations
  void _modifyMedication(BuildContext context) {
    final _nameController = TextEditingController(text: name);
    final _dosageController = TextEditingController(text: dosage.toString());
    final _typeController = TextEditingController(text: type);
    final _intervalController = TextEditingController(text: interval);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modifier les informations"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nom du médicament"),
            ),
            TextField(
              controller: _dosageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Dosage (mg)"),
            ),
            TextField(
              controller: _typeController,
              decoration: InputDecoration(labelText: "Type"),
            ),
            TextField(
              controller: _intervalController,
              decoration: InputDecoration(labelText: "Intervalle"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fermer la boîte de dialogue
                // Ajouter la logique de mise à jour ici, par exemple :
                print("Mise à jour : ${_nameController.text}");
              },
              child: Text("Sauvegarder"),
            ),
          ],
        ),
      ),
    );
  }

  // Simuler la suppression du médicament
  void _deleteMedication(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Supprimer le médicament"),
        content: Text("Êtes-vous sûr de vouloir supprimer ce médicament ?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Ajouter la logique de suppression ici
              print("Médicament supprimé");
            },
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du médicament'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nom : $name',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Dosage : $dosage mg', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Type : $type', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Intervalle : $interval', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Heure de rappel : ${DateFormat('HH:mm').format(time)}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Assistant : $assistant', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _modifyMedication(context),
                    child: Text('Modifier les informations'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _deleteMedication(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Supprimer le médicament'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
