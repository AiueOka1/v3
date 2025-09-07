import 'package:cloud_firestore/cloud_firestore.dart';

class Dog {
  final String id;
  final String name;
  final String breed;
  final String imageUrl;
  final String handlerId;
  final String handlerName;
  final String specialization;
  final String trainingLevel;
  final Map<String, dynamic> lastKnownLocation;
  final bool isActive;
  final String nfcTagId;
  final String department;
  final String medicalInfo;
  final String emergencyContact;
  final String? deviceId; // Add this field

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.imageUrl,
    required this.handlerId,
    required this.handlerName,
    required this.specialization,
    required this.trainingLevel,
    required this.lastKnownLocation,
    required this.isActive,
    required this.nfcTagId,
    required this.department,
    required this.medicalInfo,
    required this.emergencyContact,
    this.deviceId,
  });

  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      id: json['id'],
      name: json['name'],
      breed: json['breed'],
      imageUrl: json['imageUrl'],
      handlerId: json['handlerId'],
      handlerName: json['handlerName'],
      specialization: json['specialization'],
      trainingLevel: json['trainingLevel'],
      lastKnownLocation: json['lastKnownLocation'],
      isActive: json['isActive'],
      nfcTagId: json['nfcTagId'],
      department: json['department'],
      medicalInfo: json['medicalInfo'],
      emergencyContact: json['emergencyContact'],
      deviceId: json['deviceId'], // Include deviceId
    );
  }

  factory Dog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dog(
      id: doc.id,
      name: data['name'],
      breed: data['breed'],
      imageUrl: data['imageUrl'],
      handlerId: data['handlerId'],
      handlerName: data['handlerName'],
      specialization: data['specialization'],
      trainingLevel: data['trainingLevel'],
      lastKnownLocation: Map<String, dynamic>.from(data['lastKnownLocation']),
      isActive: data['isActive'],
      nfcTagId: data['nfcTagId'],
      department: data['department'],
      medicalInfo: data['medicalInfo'],
      emergencyContact: data['emergencyContact'],
      deviceId: data['deviceId'], // Make sure this is included
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'imageUrl': imageUrl,
      'handlerId': handlerId,
      'handlerName': handlerName,
      'specialization': specialization,
      'trainingLevel': trainingLevel,
      'lastKnownLocation': lastKnownLocation,
      'isActive': isActive,
      'nfcTagId': nfcTagId,
      'department': department,
      'medicalInfo': medicalInfo,
      'emergencyContact': emergencyContact,
      'deviceId': deviceId, // Include deviceId in JSON
    };
  }

  // Add the factory constructor for an empty Dog instance
  factory Dog.empty() {
    return Dog(
      id: '',
      name: '',
      breed: '',
      imageUrl: '',
      handlerId: '',
      handlerName: '',
      specialization: '',
      trainingLevel: '',
      lastKnownLocation: {},
      isActive: false,
      nfcTagId: '',
      department: '',
      medicalInfo: '',
      emergencyContact: '',
      deviceId: null,
    );
  }

  Dog copyWith({
    String? id,
    String? name,
    String? breed,
    String? imageUrl,
    String? handlerId,
    String? handlerName,
    String? specialization,
    String? trainingLevel,
    Map<String, dynamic>? lastKnownLocation,
    bool? isActive,
    String? nfcTagId,
    String? department,
    String? medicalInfo,
    String? emergencyContact,
    String? deviceId,
  }) {
    return Dog(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      imageUrl: imageUrl ?? this.imageUrl,
      handlerId: handlerId ?? this.handlerId,
      handlerName: handlerName ?? this.handlerName,
      specialization: specialization ?? this.specialization,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      isActive: isActive ?? this.isActive,
      nfcTagId: nfcTagId ?? this.nfcTagId,
      department: department ?? this.department,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
