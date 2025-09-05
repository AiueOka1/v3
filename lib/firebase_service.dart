import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  static DatabaseReference getDatabaseReference() {
    return FirebaseDatabase.instance.ref();
  }
}