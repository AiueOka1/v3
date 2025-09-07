import 'package:flutter/material.dart';
import 'package:pawtech/models/dog.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DogProvider with ChangeNotifier {
  List<Dog> _dogs = [];
  bool _isLoading = false;
  String? _error;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<Dog> get dogs => [..._dogs];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDogs() async {
    _isLoading = true;
    _error = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final snapshot =
            await FirebaseFirestore.instance
                .collection('dogs')
                .where('handlerId', isEqualTo: userId)
                .get();

        _dogs = snapshot.docs.map((doc) => Dog.fromFirestore(doc)).toList();
      } catch (e) {
        _error = e.toString();
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addDog(Dog dog) async {
    _isLoading = true;
    _error = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final docRef = await FirebaseFirestore.instance.collection('dogs').add({
          'name': dog.name,
          'breed': dog.breed,
          'imageUrl': dog.imageUrl,
          'handlerId': dog.handlerId,
          'handlerName': dog.handlerName,
          'specialization': dog.specialization,
          'trainingLevel': dog.trainingLevel,
          'lastKnownLocation': dog.lastKnownLocation,
          'isActive': dog.isActive,
          'nfcTagId': dog.nfcTagId,
          'department': dog.department,
          'medicalInfo': dog.medicalInfo,
          'emergencyContact': dog.emergencyContact,
        });

        final newDog = Dog(
          id: docRef.id,
          name: dog.name,
          breed: dog.breed,
          imageUrl: dog.imageUrl,
          handlerId: dog.handlerId,
          handlerName: dog.handlerName,
          specialization: dog.specialization,
          trainingLevel: dog.trainingLevel,
          lastKnownLocation: dog.lastKnownLocation,
          isActive: dog.isActive,
          nfcTagId: dog.nfcTagId,
          department: dog.department,
          medicalInfo: dog.medicalInfo,
          emergencyContact: dog.emergencyContact,
        );

        _dogs.add(newDog);
      } catch (e) {
        _error = e.toString();
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateDogLocation(
    String dogId,
    double latitude,
    double longitude,
  ) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final dogIndex = _dogs.indexWhere((dog) => dog.id == dogId);
        if (dogIndex == -1) {
          throw Exception('Dog not found');
        }

        final updatedDog = Dog(
          id: _dogs[dogIndex].id,
          name: _dogs[dogIndex].name,
          breed: _dogs[dogIndex].breed,
          imageUrl: _dogs[dogIndex].imageUrl,
          handlerId: _dogs[dogIndex].handlerId,
          handlerName: _dogs[dogIndex].handlerName,
          specialization: _dogs[dogIndex].specialization,
          trainingLevel: _dogs[dogIndex].trainingLevel,
          lastKnownLocation: {
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now().toIso8601String(),
          },
          isActive: _dogs[dogIndex].isActive,
          nfcTagId: _dogs[dogIndex].nfcTagId,
          department: _dogs[dogIndex].department,
          medicalInfo: _dogs[dogIndex].medicalInfo,
          emergencyContact: _dogs[dogIndex].emergencyContact,
        );

        _dogs[dogIndex] = updatedDog;
      } catch (e) {
        _error = e.toString();
      }

      notifyListeners();
    });
  }

  Future<void> updateDogStatus(String dogId, bool isActive) async {
    _isLoading = true;
    _error = null;
    
    try {
      // Update the status in Firestore first
      await FirebaseFirestore.instance
          .collection('dogs')
          .doc(dogId)
          .update({'isActive': isActive});

      // Then update the local state
      final dogIndex = _dogs.indexWhere((dog) => dog.id == dogId);
      if (dogIndex == -1) {
        throw Exception('Dog not found');
      }

      final updatedDog = _dogs[dogIndex].copyWith(isActive: isActive);
      _dogs[dogIndex] = updatedDog;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Dog? getDogById(String id) {
    try {
      return _dogs.firstWhere((dog) => dog.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Dog> getDogsForHandler(String handlerId) {
    return _dogs.where((dog) => dog.handlerId == handlerId).toList();
  }

  String generateDogShareableUrl(String dogId) {
    try {
      final dog = getDogById(dogId);
      if (dog == null) {
        throw Exception('Dog not found');
      }

      final Map<String, dynamic> dogData = {
        'id': dog.id,
        'name': dog.name,
        'breed': dog.breed,
        'handler': dog.handlerName,
        'nfc': dog.nfcTagId,
        'dept': dog.department,
      };

      final String encodedData = base64Url.encode(
        utf8.encode(json.encode(dogData)),
      );

      return 'https://pawtech.app/dog/$encodedData';
    } catch (e) {
      _error = e.toString();
      return '';
    }
  }

  Map<String, dynamic>? decodeDogUrl(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final String encodedData = uri.pathSegments.last;

      final String decodedJson = utf8.decode(base64Url.decode(encodedData));
      final Map<String, dynamic> dogData = json.decode(decodedJson);

      return dogData;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<String?> assignDeviceToDog(String dogId, String deviceId) async {
    try {
      final snapshot = await _database.child('data/$deviceId').get();

      if (!snapshot.exists) {
        return 'Device does not exist.';
      }

      final deviceData = snapshot.value as Map<dynamic, dynamic>;

      if (deviceData.containsKey('dogId') && deviceData['dogId'] != null) {
        return 'This device is already assigned to another dog.';
      }

      await _database.child('data/$deviceId').update({'dogId': dogId});

      final dogIndex = _dogs.indexWhere((dog) => dog.id == dogId);
      if (dogIndex != -1) {
        final updatedDog = Dog(
          id: _dogs[dogIndex].id,
          name: _dogs[dogIndex].name,
          breed: _dogs[dogIndex].breed,
          imageUrl: _dogs[dogIndex].imageUrl,
          handlerId: _dogs[dogIndex].handlerId,
          handlerName: _dogs[dogIndex].handlerName,
          specialization: _dogs[dogIndex].specialization,
          trainingLevel: _dogs[dogIndex].trainingLevel,
          lastKnownLocation: _dogs[dogIndex].lastKnownLocation,
          isActive: _dogs[dogIndex].isActive,
          nfcTagId: _dogs[dogIndex].nfcTagId,
          department: _dogs[dogIndex].department,
          medicalInfo: _dogs[dogIndex].medicalInfo,
          emergencyContact: _dogs[dogIndex].emergencyContact,
          deviceId: deviceId,
        );

        _dogs[dogIndex] = updatedDog;
        notifyListeners();
      }

      return null;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  Future<void> syncDeviceLocationToFirestore(String deviceId) async {
    try {
      final snapshot = await _database.child('data/$deviceId').get();

      if (!snapshot.exists) {
        throw Exception('Device does not exist.');
      }

      final deviceData = snapshot.value as Map<dynamic, dynamic>;
      final dogId = deviceData['dogId'] as String?;
      final lat = deviceData['lat']?.toDouble();
      final lon = deviceData['lon']?.toDouble();

      if (dogId == null || lat == null || lon == null) {
        throw Exception(
          'Device is not assigned to a dog or location data is missing.',
        );
      }

      await FirebaseFirestore.instance.collection('dogs').doc(dogId).update({
        'lastKnownLocation': {
          'latitude': lat,
          'longitude': lon,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });

      final dogIndex = _dogs.indexWhere((dog) => dog.id == dogId);
      if (dogIndex != -1) {
        final updatedDog = Dog(
          id: _dogs[dogIndex].id,
          name: _dogs[dogIndex].name,
          breed: _dogs[dogIndex].breed,
          imageUrl: _dogs[dogIndex].imageUrl,
          handlerId: _dogs[dogIndex].handlerId,
          handlerName: _dogs[dogIndex].handlerName,
          specialization: _dogs[dogIndex].specialization,
          trainingLevel: _dogs[dogIndex].trainingLevel,
          lastKnownLocation: {
            'latitude': lat,
            'longitude': lon,
            'timestamp': DateTime.now().toIso8601String(),
          },
          isActive: _dogs[dogIndex].isActive,
          nfcTagId: _dogs[dogIndex].nfcTagId,
          department: _dogs[dogIndex].department,
          medicalInfo: _dogs[dogIndex].medicalInfo,
          emergencyContact: _dogs[dogIndex].emergencyContact,
          deviceId: deviceId,
        );

        _dogs[dogIndex] = updatedDog;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
