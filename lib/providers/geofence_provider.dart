import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pawtech/models/geofence.dart';
import 'package:pawtech/data/mock_data.dart';
import 'package:pawtech/providers/alert_provider.dart';

class GeofenceProvider with ChangeNotifier {
  List<Geofence> _geofences = [];
  bool _isLoading = false;
  String? _error;
  final AlertProvider? alertProvider;

  GeofenceProvider({this.alertProvider});

  List<Geofence> get geofences => [..._geofences];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGeofences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      
      await Future.delayed(const Duration(seconds: 1));
      
      
      _geofences = MockData.geofences;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGeofence(Geofence geofence) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      
      await Future.delayed(const Duration(seconds: 1));
      
      
      _geofences.add(geofence);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGeofence(Geofence geofence) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      
      await Future.delayed(const Duration(seconds: 1));
      
      
      final geofenceIndex = _geofences.indexWhere((g) => g.id == geofence.id);
      if (geofenceIndex == -1) {
        throw Exception('Geofence not found');
      }
      
      
      _geofences[geofenceIndex] = geofence;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGeofence(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      
      await Future.delayed(const Duration(seconds: 1));
      
      
      _geofences.removeWhere((geofence) => geofence.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Geofence> getGeofencesForDog(String dogId) {
    return _geofences.where((geofence) => geofence.dogId == dogId).toList();
  }

  
  bool isDogWithinGeofence(String dogId, double latitude, double longitude) {
    final dogGeofences = getGeofencesForDog(dogId);
    if (dogGeofences.isEmpty) return true; 
    
    for (var geofence in dogGeofences) {
      if (!geofence.isActive) continue;
      
      
      final double distance = _calculateDistance(
        latitude, 
        longitude, 
        geofence.latitude, 
        geofence.longitude
      );
      
      if (distance <= geofence.radius) {
        return true; 
      }
    }
    
    
    return false;
  }
  
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; 
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * 
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }
}

