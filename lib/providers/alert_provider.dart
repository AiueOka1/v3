import 'package:flutter/material.dart';
import 'package:pawtech/models/alert.dart';
import 'package:pawtech/data/mock_data.dart';

class AlertProvider with ChangeNotifier {
  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<Alert> get alerts => [..._alerts];
  List<Alert> get unreadAlerts =>
      _alerts.where((alert) => !alert.isRead).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => unreadAlerts.length;

  Future<void> fetchAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      _alerts = MockData.alerts;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAlert(Alert alert) async {
    try {
      _alerts.add(alert);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
      if (alertIndex == -1) {
        throw Exception('Alert not found');
      }

      final updatedAlert = Alert(
        id: _alerts[alertIndex].id,
        dogId: _alerts[alertIndex].dogId,
        dogName: _alerts[alertIndex].dogName,
        type: _alerts[alertIndex].type,
        message: _alerts[alertIndex].message,
        location: _alerts[alertIndex].location,
        timestamp: _alerts[alertIndex].timestamp,
        isRead: true,
      );

      _alerts[alertIndex] = updatedAlert;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAlertsAsRead() async {
    try {
      _alerts =
          _alerts
              .map(
                (alert) => Alert(
                  id: alert.id,
                  dogId: alert.dogId,
                  dogName: alert.dogName,
                  type: alert.type,
                  message: alert.message,
                  location: alert.location,
                  timestamp: alert.timestamp,
                  isRead: true,
                ),
              )
              .toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      _alerts.removeWhere((alert) => alert.id == alertId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Alert> getAlertsForDog(String dogId) {
    return _alerts.where((alert) => alert.dogId == dogId).toList();
  }

  void createGeofenceWarningAlert(
    String dogId,
    String dogName,
    Map<String, dynamic> location,
  ) {
    final newAlert = Alert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      dogId: dogId,
      dogName: dogName,
      type: 'geofence_warning',
      message: '$dogName is approaching the boundary of the safe zone!',
      location: location,
      timestamp: DateTime.now().toIso8601String(),
      isRead: false,
    );

    addAlert(newAlert);
  }

  void createGeofenceBreachAlert(
    String dogId,
    String dogName,
    Map<String, dynamic> location,
  ) {
    final newAlert = Alert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      dogId: dogId,
      dogName: dogName,
      type: 'geofence_breach',
      message: '$dogName has left the designated safe zone!',
      location: location,
      timestamp: DateTime.now().toIso8601String(),
      isRead: false,
    );

    addAlert(newAlert);
  }
}
