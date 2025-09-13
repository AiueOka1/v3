import 'package:flutter/material.dart';
import 'package:pawtech/models/alert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertProvider with ChangeNotifier {
  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<Alert> get alerts => [..._alerts];
  List<Alert> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => unreadAlerts.length;

  // Firestore reference
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('alerts');

  Future<void> fetchAlerts() async {
    // Defer state changes to avoid build phase conflicts
    Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });
    
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Future.microtask(() {
          _alerts = [];
          _isLoading = false;
          notifyListeners();
        });
        return;
      }

      QuerySnapshot<Map<String, dynamic>> alertsSnapshot;
      
      try {
        // Try with orderBy first (requires Firestore index)
        alertsSnapshot = await _col
            .where('handlerId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .get();
      } catch (e) {
        // Fallback: query without orderBy (no index required)
        alertsSnapshot = await _col
            .where('handlerId', isEqualTo: currentUser.uid)
            .get();
      }
      
      final alertsList = alertsSnapshot.docs.map((doc) {
        final d = doc.data();
        return Alert(
          id: d['id'] as String,
          dogId: d['dogId'] as String,
          dogName: d['dogName'] as String,
          type: d['type'] as String,
          message: d['message'] as String,
          location: Map<String, dynamic>.from(d['location'] ?? {}),
          timestamp: d['timestamp'] as String,
          isRead: (d['isRead'] as bool?) ?? false,
          handlerId: d['handlerId'] as String?,
        );
      }).toList();
      
      // Sort by timestamp if we used the fallback query
      alertsList.sort((a, b) => DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)));
      
      Future.microtask(() {
        _alerts = alertsList;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      Future.microtask(() {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> addAlert(Alert alert) async {
    try {
      print('🔄 Adding alert: ${alert.id} for dog: ${alert.dogId}');
      
      // Get current user ID to associate the alert with the handler
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      print('👤 Current user ID: $currentUserId');
      
      if (currentUserId == null) {
        print('❌ No authenticated user found');
        Future.microtask(() {
          _error = 'User not authenticated';
          notifyListeners();
        });
        return;
      }
      
      final alertData = alert.toJson();
      
      print('📝 Alert data to store: $alertData');
      
      // Use the client-generated id so UI can reference it immediately
      await _col.doc(alert.id).set(alertData);
      print('✅ Alert stored in Firestore successfully');
      
      Future.microtask(() {
        _alerts.insert(0, alert);
        notifyListeners();
      });
      print('✅ Alert added to local state and UI notified');
    } catch (e) {
      print('❌ Failed to add alert: $e');
      Future.microtask(() {
        _error = e.toString();
        notifyListeners();
      });
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _col.doc(alertId).update({'isRead': true});
      final i = _alerts.indexWhere((a) => a.id == alertId);
      if (i != -1) {
        _alerts[i] = Alert(
          id: _alerts[i].id,
          dogId: _alerts[i].dogId,
          dogName: _alerts[i].dogName,
          type: _alerts[i].type,
          message: _alerts[i].message,
          location: _alerts[i].location,
          timestamp: _alerts[i].timestamp,
          isRead: true,
          handlerId: _alerts[i].handlerId,
        );
        Future.microtask(() => notifyListeners());
      }
    } catch (e) {
      Future.microtask(() {
        _error = e.toString();
        notifyListeners();
      });
    }
  }

  Future<void> markAllAlertsAsRead() async {
    try {
      final unread = _alerts.where((a) => !a.isRead).toList();
      final batch = FirebaseFirestore.instance.batch();
      for (final a in unread) {
        batch.update(_col.doc(a.id), {'isRead': true});
      }
      await batch.commit();

      _alerts = _alerts
          .map((a) => Alert(
                id: a.id,
                dogId: a.dogId,
                dogName: a.dogName,
                type: a.type,
                message: a.message,
                location: a.location,
                timestamp: a.timestamp,
                isRead: true,
                handlerId: a.handlerId,
              ))
          .toList();
      Future.microtask(() => notifyListeners());
    } catch (e) {
      Future.microtask(() {
        _error = e.toString();
        notifyListeners();
      });
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      await _col.doc(alertId).delete();
      _alerts.removeWhere((a) => a.id == alertId);
      Future.microtask(() => notifyListeners());
    } catch (e) {
      Future.microtask(() {
        _error = e.toString();
        notifyListeners();
      });
    }
  }

  List<Alert> getAlertsForDog(String dogId) {
    return _alerts.where((alert) => alert.dogId == dogId).toList();
  }

  void createGeofenceWarningAlert(
    String dogId,
    String dogName,
    Map<String, dynamic> location,
  ) async {
    try {
      // Get the current user ID as the handler
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      final newAlert = Alert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        dogId: dogId,
        dogName: dogName,
        type: 'geofence_warning',
        message: '$dogName is approaching the boundary of the safe zone!',
        location: location,
        timestamp: DateTime.now().toIso8601String(),
        isRead: false,
        handlerId: currentUserId,
      );
      addAlert(newAlert);
    } catch (e) {
      print('❌ Failed to create geofence warning alert: $e');
    }
  }

  void createGeofenceBreachAlert(
    String dogId,
    String dogName,
    Map<String, dynamic> location,
  ) async {
    try {
      // Get the current user ID as the handler
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      final newAlert = Alert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        dogId: dogId,
        dogName: dogName,
        type: 'geofence_breach',
        message: '$dogName has left the designated safe zone!',
        location: location,
        timestamp: DateTime.now().toIso8601String(),
        isRead: false,
        handlerId: currentUserId,
      );
      addAlert(newAlert);
    } catch (e) {
      print('❌ Failed to create geofence breach alert: $e');
    }
  }

  /// Clear all local alerts and refresh from Firestore
  Future<void> refreshAlertsFromFirestore() async {
    _alerts.clear();
    await fetchAlerts();
  }

  /// Clear all local alerts (for logout or user switching)
  void clearAlerts() {
    print('🧹 Clearing all alerts');
    
    // Use Future.microtask to ensure all state changes happen outside build phase
    Future.microtask(() {
      _alerts.clear();
      _isLoading = false;
      _error = null;
      notifyListeners();
    });
  }

  /// Initialize the alert system for a fresh start
  Future<void> initializeAlerts() async {
    print('🚀🚀🚀 UPDATED CODE RUNNING - AlertProvider.initializeAlerts() called');
    
    // Defer initial state changes to avoid build phase conflicts
    Future.microtask(() {
      print('📱 Setting initial state in microtask');
      _isLoading = true;
      _error = null;
      _alerts.clear();
      notifyListeners();
    });
    
    try {
      print('🚀 Initializing fresh alerts system...');
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        print('👤 User authenticated: ${currentUser.uid}');
        await fetchAlerts();
        print('✅ Alerts system initialized successfully');
      } else {
        print('⚠️ No authenticated user - alerts will be empty');
        Future.microtask(() {
          _isLoading = false;
          notifyListeners();
        });
      }
    } catch (e) {
      print('❌ Failed to initialize alerts: $e');
      Future.microtask(() {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    }
  }
}
