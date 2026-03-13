import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> logIntake(String event) async {
    if (_uid == null) return;

    await _firestore.collection('users').doc(_uid).collection('intake_logs').add({
      'event': event,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSettings({int? alarmHour, int? alarmMinute, int? duration, int? interval}) async {
    if (_uid == null) return;

    Map<String, dynamic> settings = {};
    if (alarmHour != null) settings['alarmHour'] = alarmHour;
    if (alarmMinute != null) settings['alarmMinute'] = alarmMinute;
    if (duration != null) settings['duration'] = duration;
    if (interval != null) settings['interval'] = interval;

    if (settings.isNotEmpty) {
      await _firestore.collection('users').doc(_uid).set({
        'settings': settings,
      }, SetOptions(merge: true));
    }
  }

  Stream<DocumentSnapshot> getSettings() {
    if (_uid == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(_uid).snapshots();
  }
}
