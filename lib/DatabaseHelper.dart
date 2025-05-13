import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'AddMedicinePage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('medications.db');
    return _database!;
  }

  // Initialisation de la base de données SQLite
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Création de la table 'medications'
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE medications (
        id $idType,
        name $textType,
        dosage $textType,
        interval $textType,
        type $textType,
        assistant $textType
      )
    ''');
  }

  // Ajouter un médicament dans la base de données
  Future<void> addMedication(Medication medication) async {
    final db = await instance.database;

    try {
      await db.insert('medications', medication.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("Error adding medication: $e");
    }
  }

  // Récupérer tous les médicaments de la base de données


  // Supprimer un médicament de la base de données
  Future<void> deleteMedication(int id) async {
    final db = await instance.database;

    try {
      await db.delete('medications', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print("Error deleting medication: $e");
    }
  }

  // Mettre à jour un médicament dans la base de données
  Future<void> updateMedication(Medication medication) async {
    final db = await instance.database;

    try {
      await db.update(
        'medications',
        medication.toMap(),
        where: 'id = ?',
        whereArgs: [medication.id],
      );
    } catch (e) {
      print("Error updating medication: $e");
    }
  }
}
