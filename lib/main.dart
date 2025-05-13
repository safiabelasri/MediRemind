import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'AddMedicinePage.dart';
import 'LoginPage.dart';

import 'NotificationService.dart';
import 'firebase_options.dart';
import 'HomePage.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
//Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //await Firebase.initializeApp();
  //print("📩 Notification en arrière-plan : ${message.notification?.title}");}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //nitialisation des notifications locales
  //await FirebaseMessaging.instance.requestPermission(); // Demande de permission pour les notifications
//  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
 // FirebaseMessaging.instance.getToken().then((token) {
    //print("🔑 Token FCM : $token");});
  // Initialiser les fuseaux horaires
  tz.initializeTimeZones();

  // Configuration pour Android
  await NotificationService.initNotifications();

// Ask for permission
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  runApp(MediRemindApp());
}

//Future<void> requestExactAlarmPermission() async {
 // if (Platform.isAndroid && await Permission.scheduleExactAlarm.isDenied) {
  //  await Permission.scheduleExactAlarm.request();}}

class MediRemindApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRemind',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthChecker(),
    );
  }
}

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Charge Firebase
        } else if (snapshot.hasData) {
          return HomePage(); // Si l'utilisateur est connecté, afficher HomePage
        } else {
          return LoginPage(); // Sinon, afficher la page de connexion
        }
      },
    );
  }
}
