import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:epo_app/data/models/medication.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> logIntake(String event, {String? medicationId}) async {
    if (_uid == null) return;

    WriteBatch batch = _firestore.batch();

    DocumentReference logRef = _firestore.collection('users').doc(_uid).collection('intake_logs').doc();
    batch.set(logRef, {
      'event': event,
      'medicationId': medicationId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (event == "INTAKE_CONFIRMED" && medicationId != null) {
      DocumentReference medRef = _firestore.collection('users').doc(_uid).collection('medications').doc(medicationId);
      batch.update(medRef, {
        'stockCount': FieldValue.increment(-1),
      });
    }

    await batch.commit();
  }

  Future<void> addMedication(Medication medication) async {
    if (_uid == null) return;
    await _firestore.collection('users').doc(_uid).collection('medications').add(medication.toMap());
  }

  Future<void> updateMedication(Medication medication) async {
    if (_uid == null) return;
    await _firestore.collection('users').doc(_uid).collection('medications').doc(medication.id).update(medication.toMap());
  }

  Stream<List<Medication>> getMedications() {
    if (_uid == null) return Stream.value([]);
    return _firestore.collection('users').doc(_uid).collection('medications').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Medication.fromMap(doc.id, doc.data())).toList();
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
