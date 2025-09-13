class Alert {
  final String id;
  final String dogId;
  final String dogName;
  final String type; // 'geofence_breach', 'low_battery', 'emergency', etc.
  final String message;
  final Map<String, dynamic> location;
  final String timestamp;
  final bool isRead;
  final String? handlerId; // Add handlerId field

  Alert({
    required this.id,
    required this.dogId,
    required this.dogName,
    required this.type,
    required this.message,
    required this.location,
    required this.timestamp,
    required this.isRead,
    this.handlerId, // Add handlerId parameter
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      dogId: json['dogId'],
      dogName: json['dogName'],
      type: json['type'],
      message: json['message'],
      location: json['location'],
      timestamp: json['timestamp'],
      isRead: json['isRead'],
      handlerId: json['handlerId'], // Add handlerId from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'dogName': dogName,
      'type': type,
      'message': message,
      'location': location,
      'timestamp': timestamp,
      'isRead': isRead,
      'handlerId': handlerId, // Add handlerId to JSON
    };
  }
}

