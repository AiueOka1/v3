class Alert {
  final String id;
  final String dogId;
  final String dogName;
  final String type; // 'geofence_breach', 'low_battery', 'emergency', etc.
  final String message;
  final Map<String, dynamic> location;
  final String timestamp;
  final bool isRead;

  Alert({
    required this.id,
    required this.dogId,
    required this.dogName,
    required this.type,
    required this.message,
    required this.location,
    required this.timestamp,
    required this.isRead,
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
    };
  }
}

