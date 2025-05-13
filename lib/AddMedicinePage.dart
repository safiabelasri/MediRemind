import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'FirebaseService.dart';
import 'LoginPage.dart';
import 'NotificationService.dart';
import 'StatisticsPage.dart';

class Medication {
  final String id;
  final String name;
  final int dosage;
  final String interval;
  final String type;
  final String assistant;
  final DateTime time;
  final int notificationId;
  final bool confirmed;
  final String notes;
  final String imageUrl;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.interval,
    required this.type,
    required this.assistant,
    required this.time,
    this.notificationId = 0,
    this.confirmed = false,
    this.notes = '',
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'interval': interval,
      'type': type,
      'assistant': assistant,
      'time': Timestamp.fromDate(time),
      'notificationId': notificationId,
      'confirmed': confirmed,
      'notes': notes,
      'imageUrl': imageUrl,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    DateTime medicationTime = map['time'] != null && map['time'] is Timestamp
        ? (map['time'] as Timestamp).toDate()
        : DateTime.now();

    return Medication(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dosage: (map['dosage'] is int) ? map['dosage'] as int : int.tryParse(map['dosage'].toString()) ?? 0,
      interval: map['interval'] ?? '',
      type: map['type'] ?? '',
      assistant: map['assistant'] ?? 'Non spécifié',
      time: medicationTime,
      notificationId: (map['notificationId'] is int) ? map['notificationId'] as int : 0,
      confirmed: map['confirmed'] ?? false,
      notes: map['notes'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

class AddMedicinePage extends StatefulWidget {
  final Medication? medication;

  const AddMedicinePage({Key? key, this.medication}) : super(key: key);

  @override
  _AddMedicinePageState createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _assistantController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? selectedMedicineType;
  String? selectedInterval;
  DateTime? selectedTime;
  String? _imageUrl;

  final List<String> medicineTypes = ['Pilule', 'Sirop', 'Injection', 'Patch', 'Gélule', 'Suppositoire'];
  final List<String> intervals = ['Chaque jour', 'Tous les 2 jours', 'Chaque semaine', 'Toutes les 12 heures', 'Toutes les 6 heures'];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage.toString();
      _assistantController.text = widget.medication!.assistant;
      _notesController.text = widget.medication!.notes;
      selectedMedicineType = widget.medication!.type;
      selectedInterval = widget.medication!.interval;
      selectedTime = widget.medication!.time;
      _imageUrl = widget.medication!.imageUrl;
    }
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    await NotificationService.requestExactAlarmPermission();
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _pickImage() async {
    // Implémenter la logique de sélection d'image
    // Cela pourrait être avec image_picker pour la caméra/galerie
    // Ou un upload vers Firebase Storage
    setState(() {
      _imageUrl = 'https://via.placeholder.com/150'; // URL temporaire
    });
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate() ||
        selectedMedicineType == null ||
        selectedInterval == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    int dosage = int.tryParse(_dosageController.text) ?? 0;
    if (dosage <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Le dosage doit être un nombre valide supérieur à 0'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      int notificationId = widget.medication?.notificationId ??
          DateTime.now().millisecondsSinceEpoch % 100000;

      Medication medication = Medication(
        id: widget.medication?.id ?? '',
        name: _nameController.text,
        dosage: dosage,
        interval: selectedInterval!,
        type: selectedMedicineType!,
        assistant: _assistantController.text,
        time: selectedTime!,
        notificationId: notificationId,
        notes: _notesController.text,
        imageUrl: _imageUrl ?? '',
      );

      if (widget.medication == null) {
        await FirebaseService().addMedication(medication.toMap());
      } else {
        await FirebaseService().updateMedication(medication.id, medication.toMap());
      }

      // Planifier la notification
      await NotificationService.scheduleRecurringNotification(
        id: notificationId,
        title: 'Rappel de médicament',
        body: '${medication.name}: ${medication.dosage}mg (${medication.type})',
        dateTime: selectedTime!,
        interval: medication.interval,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.medication == null
              ? 'Médicament ajouté avec succès'
              : 'Médicament mis à jour'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication == null ? 'Ajouter un médicament' : 'Modifier le médicament',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _saveMedication,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageUrl != null
                        ? NetworkImage(_imageUrl!)
                        : widget.medication?.imageUrl != null
                        ? NetworkImage(widget.medication!.imageUrl)
                        : null,
                    child: _imageUrl == null &&
                        (widget.medication == null || widget.medication!.imageUrl.isEmpty)
                        ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Informations Générales
              _buildSectionTitle('Informations Générales'),
              _buildTextFormField(
                controller: _nameController,
                label: 'Nom du médicament',
                icon: Icons.medication_outlined,
                validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 15),
              _buildTextFormField(
                controller: _dosageController,
                label: 'Dosage (mg)',
                icon: Icons.exposure,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 15),
              _buildTextFormField(
                controller: _assistantController,
                label: 'Nom de l\'assistant',
                icon: Icons.person_outline,
                validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 15),
              _buildTextFormField(
                controller: _notesController,
                label: 'Notes supplémentaires',
                icon: Icons.note_add_outlined,
                maxLines: 3,
              ),
              SizedBox(height: 25),

              // Paramètres du médicament
              _buildSectionTitle('Paramètres du médicament'),
              _buildDropdown(
                value: selectedMedicineType,
                items: medicineTypes,
                label: 'Type de médicament',
                icon: Icons.category_outlined,
                onChanged: (value) => setState(() => selectedMedicineType = value),
                validator: (value) => value == null ? 'Sélectionnez un type' : null,
              ),
              SizedBox(height: 15),
              _buildDropdown(
                value: selectedInterval,
                items: intervals,
                label: 'Intervalle',
                icon: Icons.schedule_outlined,
                onChanged: (value) => setState(() => selectedInterval = value),
                validator: (value) => value == null ? 'Sélectionnez un intervalle' : null,
              ),
              SizedBox(height: 15),
              _buildTimePickerButton(),
              SizedBox(height: 30),

              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.medication == null ? 'ENREGISTRER' : 'METTRE À JOUR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
    );
  }

  Widget _buildTimePickerButton() {
    return OutlinedButton(
      onPressed: _selectTime,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        side: BorderSide(color: Colors.blueAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.grey[50],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text(
            selectedTime == null
                ? 'Sélectionner l\'heure'
                : 'Heure: ${DateFormat('HH:mm').format(selectedTime!)}',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}

class MedicationListPage extends StatefulWidget {
  @override
  _MedicationListPageState createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }


  Future<void> _confirmMedication(String id) async {
    await _firebaseService.confirmMedication(id);
  }

  Future<void> _showStatistics() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StatisticsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Médicaments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(context: context, delegate: MedicationSearch());
            },
          ),
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.white),
            onPressed: _showStatistics,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => logout(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Tous'),
            Tab(text: 'À prendre'),
            Tab(text: 'Pris'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicationList(false), // Tous
          _buildMedicationList(false), // À prendre
          _buildMedicationList(true),  // Pris
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddMedicinePage()),
        ),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMedicationList(bool showOnlyConfirmed) {
    return StreamBuilder<List<Medication>>(
      stream: _firebaseService.getMedications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: _buildErrorWidget(snapshot.error.toString()));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: _buildEmptyState());
        }

        List<Medication> medications = snapshot.data!
            .where((med) => showOnlyConfirmed ? med.confirmed : true)
            .where((med) => med.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (medications.isEmpty) {
          return Center(child: _buildEmptyState(filtered: true));
        }

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            Medication med = medications[index];
            return _buildMedicationCard(med);
          },
        );
      },
    );
  }

  Widget _buildMedicationCard(Medication med) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicationDetailPage(
                medicationId: med.id,
                name: med.name,
                dosage: med.dosage,
                type: med.type,
                interval: med.interval,
                time: med.time,
                assistant: med.assistant,
                notes: med.notes,
                imageUrl: med.imageUrl,
                confirmed: med.confirmed,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              // Image/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: med.confirmed ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: med.imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    med.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.medication, size: 30, color: Colors.blueAccent),
                  ),
                )
                    : Icon(Icons.medication, size: 30,
                    color: med.confirmed ? Colors.green : Colors.blueAccent),
              ),
              SizedBox(width: 15),

              // Détails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          med.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: med.confirmed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (med.confirmed)
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      '${med.dosage}mg • ${med.type}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.blueAccent),
                        SizedBox(width: 5),
                        Text(
                          DateFormat('HH:mm').format(med.time),
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.repeat, size: 16, color: Colors.blueAccent),
                        SizedBox(width: 5),
                        Text(
                          med.interval,
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) => _handlePopupMenuSelection(value, med),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                    if (!med.confirmed)
                      PopupMenuItem(
                        value: 'confirm',
                        child: Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Confirmer la prise'),
                          ],
                        ),
                      ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePopupMenuSelection(String value, Medication med) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMedicinePage(medication: med),
          ),
        );
        break;
      case 'delete':
        _showDeleteDialog(med);
        break;
      case 'confirm':
        await _confirmMedication(med.id);
        break;
    }
  }

  void _showDeleteDialog(Medication med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${med.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _firebaseService.deleteMedication(med.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${med.name} a été supprimé'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/error.svg',
          height: 150,
          color: Colors.red,
        ),
        SizedBox(height: 20),
        Text(
          'Une erreur est survenue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() {}),
          child: Text('Réessayer'),
        ),
      ],
    );
  }

  Widget _buildEmptyState({bool filtered = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/empty.svg',
          height: 150,
          color: Colors.blueAccent,
        ),
        SizedBox(height: 20),
        Text(
          filtered ? 'Aucun résultat trouvé' : 'Aucun médicament enregistré',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          filtered
              ? 'Essayez avec un autre terme de recherche'
              : 'Commencez par ajouter votre premier médicament',
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 20),
        if (!filtered)
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddMedicinePage()),
            ),
            child: Text('Ajouter un médicament'),
          ),
      ],
    );
  }
}

extension on FirebaseService {
  getAllMedications() {}
}

class MedicationDetailPage extends StatelessWidget {
  final String medicationId;
  final String name;
  final int dosage;
  final String type;
  final String interval;
  final DateTime time;
  final String assistant;
  final String notes;
  final String imageUrl;
  final bool confirmed;

  const MedicationDetailPage({
    Key? key,
    required this.medicationId,
    required this.name,
    required this.dosage,
    required this.type,
    required this.interval,
    required this.time,
    required this.assistant,
    this.notes = '',
    this.imageUrl = '',
    this.confirmed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du médicament'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddMedicinePage(
                  medication: Medication(
                    id: medicationId,
                    name: name,
                    dosage: dosage,
                    type: type,
                    interval: interval,
                    time: time,
                    assistant: assistant,
                    notes: notes,
                    imageUrl: imageUrl,
                    confirmed: confirmed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.medication, size: 60, color: Colors.blueAccent),
                  ),
                )
                    : Icon(Icons.medication, size: 60, color: Colors.blueAccent),
              ),
            ),
            SizedBox(height: 30),

            // Nom et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(confirmed ? 'Pris' : 'À prendre'),
                  backgroundColor: confirmed ? Colors.green[100] : Colors.orange[100],
                  labelStyle: TextStyle(
                    color: confirmed ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Détails
            _buildDetailItem('Dosage', '$dosage mg', Icons.exposure),
            _buildDetailItem('Type', type, Icons.category),
            _buildDetailItem('Intervalle', interval, Icons.repeat),
            _buildDetailItem('Heure', DateFormat('HH:mm').format(time), Icons.access_time),
            _buildDetailItem('Assistant', assistant, Icons.person),

            // Notes
            if (notes.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                'Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(notes),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MedicationSearch extends SearchDelegate<String> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<Medication>>(
      stream: _firebaseService.getMedications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        List<Medication> medications = snapshot.data!
            .where((med) => med.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (medications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Aucun médicament trouvé pour "$query"',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: medications.length,
          itemBuilder: (context, index) {
            Medication med = medications[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: med.confirmed ? Colors.green[100] : Colors.blue[100],
                child: Icon(
                  Icons.medication,
                  color: med.confirmed ? Colors.green : Colors.blueAccent,
                ),
              ),
              title: Text(med.name),
              subtitle: Text('${med.dosage}mg • ${DateFormat('HH:mm').format(med.time)}'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                close(context, med.name);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicationDetailPage(
                      medicationId: med.id,
                      name: med.name,
                      dosage: med.dosage,
                      type: med.type,
                      interval: med.interval,
                      time: med.time,
                      assistant: med.assistant,
                      notes: med.notes,
                      imageUrl: med.imageUrl,
                      confirmed: med.confirmed,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
