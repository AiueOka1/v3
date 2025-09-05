import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSync {
  static final _rtdb = FirebaseDatabase.instance.ref('data');
  static final _firestore = FirebaseFirestore.instance.collection('dogs');

  
  static void startSync(String deviceId, String dogId) {
    _rtdb.child(deviceId).onValue.listen((event) async {
      final data = event.snapshot.value as Map?;
      if (data == null || data['lat'] == null || data['lon'] == null) return;

      await _firestore.doc(dogId).update({
        'lastKnownLocation': {
          'latitude': data['lat'],
          'longitude': data['lon'],
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
    });
  }

  
  static void stopSync(String deviceId) {
    _rtdb.child(deviceId).onValue.drain();
  }
}