import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AddMedicinePage.dart';
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Medication>> getMedications() {
    final user = _auth.currentUser;
    if (user == null) {
      print("⚠️ Aucun utilisateur connecté !");
      return Stream.value([]); // Retourne une liste vide si aucun utilisateur connecté
    }
    final CollectionReference _medicationCollection =
    FirebaseFirestore.instance.collection('medications');
    Future<String> addMedication(Map<String, dynamic> medicationData) async {
      DocumentReference docRef = await _medicationCollection.add(medicationData);
      return docRef.id; // Retourne l’ID du document
    }
    return _firestore
        .collection('medications')
        .where('userId', isEqualTo: user.uid) // Filtre par utilisateur
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Medication.fromMap({
          ...data,
          'id': doc.id, // On inclut aussi l'ID du document
        });
      }).toList();

    });
  }
  Future<void> confirmMedication(String id) async {
    await FirebaseFirestore.instance
        .collection('medications')
        .doc(id)
        .update({'confirmed': true});
  }

  Future<void> addMedication(Map<String, dynamic> medicationData) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("⚠️ Impossible d'ajouter, aucun utilisateur connecté !");
      return;
    }

    medicationData['userId'] = user.uid; // Associe l'utilisateur au médicament
    await _firestore.collection('medications').add(medicationData);
  }
  Future<List<Medication>> getAllMedications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('medications')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();

    return snapshot.docs
        .map((doc) => Medication.fromMap(doc.data()))
        .toList();
  }
  Future<void> deleteMedication(String id) async {
    await _firestore.collection('medications').doc(id).delete();
  }

  updateMedication(String id, Map<String, dynamic> map) {}
}
