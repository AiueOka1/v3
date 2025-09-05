class Geofence {
  final String id;
  final String name;
  final String dogId;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isActive;
  final String description;
  final String createdAt;
  final String updatedAt;

  Geofence({
    required this.id,
    required this.name,
    required this.dogId,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      id: json['id'],
      name: json['name'],
      dogId: json['dogId'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'],
      isActive: json['isActive'],
      description: json['description'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dogId': dogId,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isActive': isActive,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

