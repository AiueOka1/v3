import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawtech/models/dog.dart';
import 'package:pawtech/models/geofence.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pawtech/providers/alert_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> showGeofenceBreachNotification(String dogName) async {
  // Initialize notifications if not already done
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await _localNotifications.initialize(initSettings);

  // Request iOS permissions if needed
  if (Platform.isIOS) {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'geofence_channel',
    'Geofence Alerts',
    importance: Importance.max,
    priority: Priority.high,
  );
  
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _localNotifications.show(
    1,
    'Geofence Breach',
    '$dogName has left the safe area!',
    notificationDetails,
  );
}

class _CircleInfo {
  final String dogName;
  final String? timestampIso;
  final LatLng center;
  const _CircleInfo({
    required this.dogName,
    required this.center,
    this.timestampIso,
  });
}

enum TimeFilterPreset { lastHour, last6h, last24h, today, all, custom }

class RealMapView extends StatefulWidget {
  final String? selectedDogId;
  final List<Dog> dogs;
  final List<Geofence> geofences;
  final String geofenceLocation;
  final double geofenceRadius;

  const RealMapView({
    super.key,
    this.selectedDogId,
    required this.dogs,
    required this.geofences,
    required this.geofenceLocation,
    required this.geofenceRadius,
  });

  @override
  State<RealMapView> createState() => _RealMapViewState();
}

class _RealMapViewState extends State<RealMapView> {
  final _database = FirebaseDatabase.instance.ref().child('data');
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentUserPosition;
  final Map<String, Marker> _markers = {};
  final Map<String, Polyline> _polylines = {}; // device paths
  final Map<String, Circle> _deviceCircles = {}; // previous location circles
  final Map<String, DateTime> _deviceLastSeen = {};
  final Map<String, _CircleInfo> _circleInfo = {};
  String? _selectedCircleId;
  StreamSubscription<DatabaseEvent>? _databaseSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  bool _isTracking = false;
  Timer? _geofenceCheckTimer;
  Timer? _autoRefreshTimer;
  DateTime _lastRealtimeUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, bool> _dogInGeofenceStatus = {};
  final Map<String, bool> _dogNearBoundaryStatus = {};
  
  // Cache for custom dog icons to improve performance
  final Map<String, BitmapDescriptor> _iconCache = {};

  // Time filter state
  TimeFilterPreset _timeFilter = TimeFilterPreset.last6h;
  DateTime? _filterStart;
  DateTime? _filterEnd;

  // Cache last DB snapshot so we can re-apply filters immediately
  dynamic _lastDbValue;

  // Accepts num, "12.34", or strings like "Value 12.34"
  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(v);
      if (m != null) return double.tryParse(m.group(0)!);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Default: last 6 hours
    final now = DateTime.now();
    _filterStart = now.subtract(const Duration(hours: 6));
    _filterEnd = now;

    _setupAuthListener();
    _checkLocationPermission();
    _listenToDatabaseChanges();
    _startGeofenceMonitoring();
    _startAutoRefresh(); // periodic refresh
  }

  @override
  void dispose() {
    _databaseSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _authStateSubscription?.cancel();
    _geofenceCheckTimer?.cancel();
    _autoRefreshTimer?.cancel(); // stop timer
    super.dispose();
  }

  void _setupAuthListener() {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (!mounted) return;
        
        if (user == null) {
          // User logged out, clean up everything
          print('User logged out, cleaning up map data and listeners');
          _databaseSubscription?.cancel();
          _databaseSubscription = null;
          _autoRefreshTimer?.cancel();
          _geofenceCheckTimer?.cancel();
          
          if (mounted) {
            setState(() {
              _markers.clear();
              _polylines.clear();
              _deviceCircles.clear();
              _circleInfo.clear();
              _lastDbValue = null;
            });
          }
        } else {
          // User logged in, restart listeners if needed
          if (_databaseSubscription == null) {
            _listenToDatabaseChanges();
            _startGeofenceMonitoring();
            _startAutoRefresh();
          }
        }
      },
    );
  }

  void _startGeofenceMonitoring() {
    _geofenceCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _checkGeofenceStatus();
    });
  }

  void _checkGeofenceStatus() {
    if (_markers.isEmpty) return;

    final geofenceCenter = _getGeofenceCenter();
    
    // For current location mode, skip checking if GPS isn't available
    if (widget.geofenceLocation == 'current' && _currentUserPosition == null) {
      print('⚠️ Cannot check geofence status: current location mode but GPS not available');
      return;
    }
    
    final double warningThreshold = widget.geofenceRadius * 0.8;

    _markers.forEach((deviceId, marker) {
      final distance = _calculateDistance(
        geofenceCenter.latitude,
        geofenceCenter.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );

      final bool wasInGeofence = _dogInGeofenceStatus[deviceId] ?? true;
      final bool isInGeofence = distance <= widget.geofenceRadius;

      final bool wasNearBoundary = _dogNearBoundaryStatus[deviceId] ?? false;
      final bool isNearBoundary =
          distance >= warningThreshold && distance <= widget.geofenceRadius;

      _dogInGeofenceStatus[deviceId] = isInGeofence;
      _dogNearBoundaryStatus[deviceId] = isNearBoundary;

      if (!wasNearBoundary && isNearBoundary) {
        _showApproachingBoundaryAlert(marker);
      }

      if (wasInGeofence && !isInGeofence) {
        _showGeofenceBreachAlert(marker);
      }
    });
  }

  LatLng _getGeofenceCenter() {
    // Check the geofence location setting
    if (widget.geofenceLocation == 'current') {
      // When set to current location, always follow the user
      if (_currentUserPosition != null) {
        print('🎯 Geofence set to current location - following user: ${_currentUserPosition!.latitude}, ${_currentUserPosition!.longitude}');
        return _currentUserPosition!;
      } else {
        print('⚠️ Geofence set to current location but GPS unavailable, using fallback: 14.6580779, 120.9767746');
        return const LatLng(14.6580779, 120.9767746);
      }
    } else {
      // When set to city hall or other fixed location, use that location
      print('🏛️ Geofence set to city hall location: 14.6580779, 120.9767746');
      return const LatLng(
        14.6580779,
        120.9767746,
      ); // City Hall/STI coordinates
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  void _showApproachingBoundaryAlert(Marker marker) {
    final dogName = marker.infoWindow.title ?? 'Unknown Dog';
    final dogId = marker.infoWindow.snippet ?? 'unknown';

    final alertProvider = Provider.of<AlertProvider>(context, listen: false);

    alertProvider.createGeofenceWarningAlert(dogId, dogName, {
      'latitude': marker.position.latitude,
      'longitude': marker.position.longitude,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$dogName is approaching the boundary of the safe zone!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showGeofenceBreachAlert(Marker marker) async {
    final dogName = marker.infoWindow.title ?? 'Unknown Dog';
    final dogId = marker.infoWindow.snippet ?? 'unknown';

    final alertProvider = Provider.of<AlertProvider>(context, listen: false);

    alertProvider.createGeofenceBreachAlert(dogId, dogName, {
      'latitude': marker.position.latitude,
      'longitude': marker.position.longitude,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$dogName has left the safe zone!'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );

    await showGeofenceBreachNotification(dogName);
  }

  Future<void> _checkLocationPermission() async {
    // Use Geolocator instead of permission_handler for better iOS compatibility
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Handle the case where permission is permanently denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission is permanently denied. Please enable it in Settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }
    
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      _startLiveLocationTracking();
    }
  }

  void _startLiveLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // Reduced to 1 meter for very frequent updates when testing geofence
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!mounted) return;

        final newPosition = LatLng(position.latitude, position.longitude);
        final bool locationChanged = _currentUserPosition == null || 
            (_currentUserPosition!.latitude != newPosition.latitude || 
             _currentUserPosition!.longitude != newPosition.longitude);

        setState(() {
          _currentUserPosition = newPosition;

          if (_isTracking) {
            _moveCameraToCurrentPosition();
          }
          
          // The setState will automatically trigger a rebuild of the geofence circles
          // since _buildGeofenceCircles() depends on _currentUserPosition
        });

        // Log when user location changes to help with debugging
        if (locationChanged) {
          print('📍 User location updated: ${newPosition.latitude}, ${newPosition.longitude}');
          if (widget.geofenceLocation == 'current') {
            print('🎯 Geofence should update to follow user location');
          }
          print('🔄 Geofence circles will be rebuilt automatically');
        }
      },
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location tracking error: ${e.toString()}')),
        );
      },
    );
  }

  Future<void> _moveCameraToCurrentPosition() async {
    if (_currentUserPosition == null) return;

    try {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentUserPosition!, 16),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera update failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _moveCameraToCityHall() async {
    try {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          const LatLng(14.6580779, 120.9767746),
          16,
        ),
      );
      
      print('🏛️ Moved camera to city hall: 14.6580779, 120.9767746');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera update failed: ${e.toString()}')),
      );
    }
  }

  void _toggleLocationTracking() {
    setState(() {
      _isTracking = !_isTracking;
      if (_isTracking && _currentUserPosition != null) {
        _moveCameraToCurrentPosition();
      }
    });
  }

  // Parse timestamp (ISO string or epoch seconds/millis) -> DateTime?
  DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();

    // Try ISO
    DateTime? dt = DateTime.tryParse(s);
    if (dt != null) return dt;

    // Try digits -> epoch
    if (RegExp(r'^\d+$').hasMatch(s)) {
      final v = int.tryParse(s);
      if (v != null) {
        // 13+ digits -> ms; else seconds
        dt = s.length >= 13
            ? DateTime.fromMillisecondsSinceEpoch(v, isUtc: true)
            : DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true);
        return dt;
      }
    }
    return null;
  }

  bool _withinFilter(DateTime? dt) {
    if (dt == null) return false;

    final now = DateTime.now();

    switch (_timeFilter) {
      case TimeFilterPreset.lastHour: {
        final start = now.subtract(const Duration(hours: 1));
        return !dt.isBefore(start) && !dt.isAfter(now);
      }
      case TimeFilterPreset.last6h: {
        final start = now.subtract(const Duration(hours: 6));
        return !dt.isBefore(start) && !dt.isAfter(now);
      }
      case TimeFilterPreset.last24h: {
        final start = now.subtract(const Duration(hours: 24));
        return !dt.isBefore(start) && !dt.isAfter(now);
      }
      case TimeFilterPreset.today: {
        final start = DateTime(now.year, now.month, now.day);
        return !dt.isBefore(start) && !dt.isAfter(now);
      }
      case TimeFilterPreset.all:
        return true;
      case TimeFilterPreset.custom: {
        // Use user-picked fixed range
        final start = _filterStart;
        final end = _filterEnd;
        if (start == null && end == null) return true;
        if (start != null && dt.isBefore(start)) return false;
        if (end != null && dt.isAfter(end)) return false;
        return true;
      }
    }
  }

  void _setTimePreset(TimeFilterPreset p) {
    final now = DateTime.now();
    setState(() {
      _timeFilter = p;
      switch (p) {
        case TimeFilterPreset.lastHour:
          _filterStart = now.subtract(const Duration(hours: 1));
          _filterEnd = now;
          break;
        case TimeFilterPreset.last6h:
          _filterStart = now.subtract(const Duration(hours: 6));
          _filterEnd = now;
          break;
        case TimeFilterPreset.last24h:
          _filterStart = now.subtract(const Duration(hours: 24));
          _filterEnd = now;
          break;
        case TimeFilterPreset.today:
          _filterStart = DateTime(now.year, now.month, now.day);
          _filterEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case TimeFilterPreset.all:
          _filterStart = null;
          _filterEnd = null;
          break;
        case TimeFilterPreset.custom:
          // keep whatever custom values were set
          break;
      }
    });
    _rebuildFromCache();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialStart = _filterStart ?? now.subtract(const Duration(days: 1));
    final initialEnd = _filterEnd ?? now;

    // First, pick the date range
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (!mounted || range == null) return;

    // Then pick start time
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialStart),
      helpText: 'Select start time',
    );

    if (!mounted || startTime == null) return;

    // Then pick end time
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialEnd),
      helpText: 'Select end time',
    );

    if (!mounted || endTime == null) return;

    setState(() {
      _timeFilter = TimeFilterPreset.custom;
      // Combine date and time for start
      _filterStart = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
        startTime.hour,
        startTime.minute,
      );
      // Combine date and time for end
      _filterEnd = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        endTime.hour,
        endTime.minute,
      );
    });
    _rebuildFromCache();
  }

  // Create a custom dog icon for the map marker
  Future<BitmapDescriptor> _createDogIcon(Color color, bool isSelected) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      const double size = 160.0; // Increased overall size even more

      // Draw shadow effect
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      // Create teardrop/pin shape with shadow
      final Path shadowPath = Path();
      const double centerX = size / 2 + 1;
      const double centerY = size / 2 - 8 + 1; // Adjusted for larger size
      const double radius = 40.0; // Increased radius even more
      
      // Draw circle part of the teardrop
      shadowPath.addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
      // Add the pointed bottom
      shadowPath.moveTo(centerX, centerY + radius);
      shadowPath.lineTo(centerX - 14, centerY + radius + 24); // Scaled up more
      shadowPath.lineTo(centerX + 14, centerY + radius + 24);
      shadowPath.close();
      canvas.drawPath(shadowPath, shadowPaint);

      // Create main teardrop/pin shape
      final Paint bgPaint = Paint()
        ..color = isSelected ? Colors.blue : Colors.orange
        ..style = PaintingStyle.fill;
      
      final Path mainPath = Path();
      const double mainCenterX = size / 2;
      const double mainCenterY = size / 2 - 8; // Adjusted for larger size
      
      // Draw circle part of the teardrop
      mainPath.addOval(Rect.fromCircle(center: Offset(mainCenterX, mainCenterY), radius: radius));
      // Add the pointed bottom triangle
      mainPath.moveTo(mainCenterX, mainCenterY + radius);
      mainPath.lineTo(mainCenterX - 14, mainCenterY + radius + 24); // Scaled up more
      mainPath.lineTo(mainCenterX + 14, mainCenterY + radius + 24);
      mainPath.close();
      canvas.drawPath(mainPath, bgPaint);

      // Draw white border around the entire shape
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0; // Even thicker border
      canvas.drawPath(mainPath, borderPaint);

      // Draw dog paw print icon in the circular part
      final Paint iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      // Main pad (oval) - positioned in the circular area - scaled up even more
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mainCenterX, mainCenterY + 3),
          width: 34, // Increased from 30
          height: 25, // Increased from 22
        ),
        iconPaint,
      );

      // Four toe pads (circles) - arranged like a real paw in the circular area - scaled up even more
      const double toeRadius = 8.0; // Increased from 7.0
      canvas.drawCircle(Offset(mainCenterX - 16, mainCenterY - 9), toeRadius, iconPaint); // Adjusted positions
      canvas.drawCircle(Offset(mainCenterX + 16, mainCenterY - 9), toeRadius, iconPaint);
      canvas.drawCircle(Offset(mainCenterX - 7, mainCenterY - 17), toeRadius, iconPaint);
      canvas.drawCircle(Offset(mainCenterX + 7, mainCenterY - 17), toeRadius, iconPaint);

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(size.round(), size.round());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      // Fallback to colored default markers if custom icon creation fails
      if (isSelected) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      } else {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }
    }
  }

  void _rebuildFromCache() {
    if (_lastDbValue == null) return;
    _rebuildFromRaw(_lastDbValue);
  }

  // Extracted builder so we can reuse it on filter changes
  void _rebuildFromRaw(dynamic value) async {
    if (!mounted) return;

    if (value == null) {
      setState(() {
        _markers.clear();
        _polylines.clear();
        _deviceCircles.clear();
        _circleInfo.clear();
      });
      return;
    }

    if (value is! Map) return;
    final data = value as Map<dynamic, dynamic>;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final userDogs = widget.dogs.where((dog) => dog.handlerId == currentUserId).toList();
    // Only include active dogs on the map
    final activeDogs = userDogs.where((dog) => dog.isActive).toList();
    final activeDogIds = activeDogs.map((dog) => dog.id).toSet();

    final Map<String, String> dogNameById = {
      for (final d in activeDogs) d.id: (d.name.trim().isNotEmpty ? d.name.trim() : 'Unknown Dog'),
    };

    final Map<String, Marker> newMarkers = {};
    final Map<String, Polyline> newPolylines = {};
    final Map<String, Circle> newDeviceCircles = {};
    final Map<String, _CircleInfo> newCircleInfo = {};
    final Set<String> validDeviceIds = {};

    for (final deviceId in data.keys) {
      final deviceData = data[deviceId];
      if (deviceData is! Map) continue;

      final dogId = deviceData['dogId'] as String?;
      if (dogId == null || !activeDogIds.contains(dogId)) continue;

      _deviceLastSeen[deviceId as String] = DateTime.now();
      validDeviceIds.add(deviceId as String);

      final locations = deviceData['locations'] as Map<dynamic, dynamic>?;
      if (locations == null || locations.isEmpty) continue;

      // Sort ascending by timestamp
      final rawEntries = locations.values.whereType<Map>().toList()
        ..sort((a, b) {
          final aTs = _parseTimestamp(a['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTs = _parseTimestamp(b['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aTs.compareTo(bTs);
        });

      // Apply time filter
      final entries = rawEntries.where((e) => _withinFilter(_parseTimestamp(e['timestamp']))).toList();
      if (entries.isEmpty) continue;

      // Collect valid points within filter
      final List<LatLng> points = [];
      for (final e in entries) {
        final lat = _toDouble(e['lat']);
        final lon = _toDouble(e['lon']);
        if (lat != null && lon != null) points.add(LatLng(lat, lon));
      }
      if (points.isEmpty) continue;

      // Limit points for performance
      const maxPoints = 300;
      final pathPoints = points.length > maxPoints ? points.sublist(points.length - maxPoints) : points;

      // Find last valid entry within filtered set
      int latestIndex = -1;
      Map<dynamic, dynamic>? latestValid;
      for (int i = entries.length - 1; i >= 0; i--) {
        final lt = _toDouble(entries[i]['lat']);
        final ln = _toDouble(entries[i]['lon']);
        if (lt != null && ln != null) {
          latestValid = entries[i];
          latestIndex = i;
          break;
        }
      }
      if (latestValid == null) continue;

      // Previous valid entry (within filtered set)
      Map<dynamic, dynamic>? previousValid;
      for (int i = latestIndex - 1; i >= 0; i--) {
        final lt = _toDouble(entries[i]['lat']);
        final ln = _toDouble(entries[i]['lon']);
        if (lt != null && ln != null) {
          previousValid = entries[i];
          break;
        }
      }

      final latestLat = _toDouble(latestValid['lat'])!;
      final latestLon = _toDouble(latestValid['lon'])!;
      final tsStr = latestValid['timestamp']?.toString();

      try {
        await FirebaseFirestore.instance.collection('dogs').doc(dogId).update({
          'lastKnownLocation': {'latitude': latestLat, 'longitude': latestLon, 'timestamp': tsStr},
        });
      } catch (_) {}

      final dog = activeDogs.firstWhere((d) => d.id == dogId, orElse: () => Dog.empty());
      final displayDogName = dogNameById[dogId] ?? 'Unknown Dog';

      // Create custom dog icon with appropriate color (using cache for performance)
      final markerColor = widget.selectedDogId == dogId ? Colors.blue : Colors.red;
      final isSelected = widget.selectedDogId == dogId;
      final cacheKey = '${markerColor.value}_$isSelected';
      
      BitmapDescriptor dogIcon;
      if (_iconCache.containsKey(cacheKey)) {
        dogIcon = _iconCache[cacheKey]!;
      } else {
        dogIcon = await _createDogIcon(markerColor, isSelected);
        _iconCache[cacheKey] = dogIcon;
      }

      newMarkers[deviceId as String] = Marker(
        markerId: MarkerId(deviceId as String),
        position: LatLng(latestLat, latestLon),
        infoWindow: InfoWindow(title: dog.name.isNotEmpty ? dog.name : 'Unknown Dog', snippet: dogId),
        icon: dogIcon,
      );

      if (pathPoints.length >= 2) {
        newPolylines[deviceId as String] = Polyline(
          polylineId: PolylineId('path_${deviceId as String}'),
          points: pathPoints,
          width: 4,
          color: Colors.blueAccent,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          patterns: [PatternItem.dot, PatternItem.gap(12.0)],
        );
      }

      if (previousValid != null) {
        final prevLat = _toDouble(previousValid['lat'])!;
        final prevLon = _toDouble(previousValid['lon'])!;
        final prevKey = 'prev_circle_${deviceId as String}';

        newDeviceCircles[prevKey] = Circle(
          circleId: CircleId(prevKey),
          center: LatLng(prevLat, prevLon),
          radius: 5,
          fillColor: Colors.red,
          strokeColor: Colors.black,
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => _onCircleTap(prevKey),
        );

        newCircleInfo[prevKey] = _CircleInfo(
          dogName: displayDogName,
          center: LatLng(prevLat, prevLon),
          timestampIso: previousValid['timestamp']?.toString(),
        );
      }

      const int maxHistoryCircles = 150;
      if (entries.isNotEmpty) {
        final startIdx = (entries.length - maxHistoryCircles) > 0 ? (entries.length - maxHistoryCircles) : 0;

        for (int i = startIdx; i < entries.length; i++) {
          if (i == latestIndex) continue;
          final e = entries[i];
          final lat = _toDouble(e['lat']);
          final lon = _toDouble(e['lon']);
          if (lat == null || lon == null) continue;

          final circleKey = 'hist_circle_${deviceId as String}_$i';
          newDeviceCircles[circleKey] = Circle(
            circleId: CircleId(circleKey),
            center: LatLng(lat, lon),
            radius: 5,
            fillColor: Colors.red,
            strokeColor: Colors.black,
            strokeWidth: 2,
            consumeTapEvents: true,
            onTap: () => _onCircleTap(circleKey),
          );

          newCircleInfo[circleKey] = _CircleInfo(
            dogName: displayDogName,
            center: LatLng(lat, lon),
            timestampIso: e['timestamp']?.toString(),
          );
        }
      }
    }

    if (!mounted) return;
    setState(() {
      // Replace instead of merge to respect the active time filter
      _markers
        ..clear()
        ..addAll(newMarkers);
      _polylines
        ..clear()
        ..addAll(newPolylines);
      _deviceCircles
        ..clear()
        ..addAll(newDeviceCircles);
      _circleInfo
        ..clear()
        ..addAll(newCircleInfo);

      if (_selectedCircleId != null && !_circleInfo.containsKey(_selectedCircleId)) {
        _selectedCircleId = null;
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;

      // Re-apply the current rolling window against cached data
      _rebuildFromCache();

      // If no realtime event in a while, force a lightweight fetch
      final idle = DateTime.now().difference(_lastRealtimeUpdate);
      if (idle > const Duration(seconds: 15)) {
        await _refreshFromServer();
      }
    });
  }

  Future<void> _refreshFromServer() async {
    try {
      final snapshot = await _database.get();
      if (!mounted) return;
      _lastRealtimeUpdate = DateTime.now();
      _lastDbValue = snapshot.value;
      _rebuildFromRaw(_lastDbValue);
    } catch (_) {
      // ignore transient failures
    }
  }

  void _listenToDatabaseChanges() {
    _databaseSubscription = _database.onValue.listen(
      (event) async {
        if (!mounted) return;
        _lastRealtimeUpdate = DateTime.now();
        _lastDbValue = event.snapshot.value; // cache raw
        _rebuildFromRaw(_lastDbValue);       // build using current filter
      },
      onError: (error) {
        // Handle database permission errors (e.g., when user logs out)
        if (!mounted) return;
        print('Database listener error: $error');
        
        // If it's a permission error, clean up and stop listening
        if (error.toString().contains('permission')) {
          _databaseSubscription?.cancel();
          _databaseSubscription = null;
          
          // Clear existing data
          if (mounted) {
            setState(() {
              _markers.clear();
              _polylines.clear();
              _deviceCircles.clear();
              _circleInfo.clear();
            });
          }
        }
      },
    );
  }

  // Handle tapping a history circle (select + recenter camera)
  void _onCircleTap(String circleId) async {
    setState(() => _selectedCircleId = circleId);
    final info = _circleInfo[circleId];
    if (info == null) return;

    try {
      if (!_controller.isCompleted) return;
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(info.center, 17),
      );
    } catch (_) {}
  }

  // Draw the geofence circle
  Set<Circle> _buildGeofenceCircles() {
    final center = _getGeofenceCenter();
    
    // For current location mode, only show circles if GPS is available
    if (widget.geofenceLocation == 'current' && _currentUserPosition == null) {
      print('⚠️ Cannot display geofence circles: current location mode but GPS not available');
      return {};
    }
    
    final mode = widget.geofenceLocation == 'current' 
        ? 'Following user in real-time' 
        : 'Fixed at city hall';
    
    print('🎯 Building geofence circles at: ${center.latitude}, ${center.longitude} with radius: ${widget.geofenceRadius}m');
    print('🔄 Geofence mode: $mode');
    
    // Create unique circle IDs based on center position to force updates
    final centerKey = '${center.latitude.toStringAsFixed(6)}_${center.longitude.toStringAsFixed(6)}';
    
    return {
      // Main geofence boundary circle
      Circle(
        circleId: CircleId('geofence_main_$centerKey'),
        center: center,
        radius: widget.geofenceRadius,
        fillColor: Colors.green.withOpacity(0.2), // Made more visible
        strokeColor: Colors.green,
        strokeWidth: 4, // Made thicker
      ),
      // Add a warning zone circle (80% of main radius)
      Circle(
        circleId: CircleId('geofence_warning_$centerKey'),
        center: center,
        radius: widget.geofenceRadius * 0.8,
        fillColor: Colors.orange.withOpacity(0.1),
        strokeColor: Colors.orange,
        strokeWidth: 3,
      ),
    };
  }

  // Format timestamps shown in the top info card
  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unknown time';
    final dt = _parseTimestamp(raw)?.toLocal() ?? DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;

    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.month)}/${two(dt.day)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  // Zoom to the currently selected dog (by widget.selectedDogId)
  Future<void> _zoomToSelectedDog() async {
    final selectedId = widget.selectedDogId;
    if (selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No dog selected')),
      );
      return;
    }

    // Find the marker whose snippet holds the dogId
    Marker? m;
    for (final marker in _markers.values) {
      if (marker.infoWindow.snippet == selectedId) {
        m = marker;
        break;
      }
    }

    if (m == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected dog not visible')),
      );
      return;
    }

    try {
      if (!_controller.isCompleted) return;
      final controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(m.position, 17));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera update failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            if (!_controller.isCompleted) {
              _controller.complete(controller);
            }
          },
          onTap: (_) => setState(() => _selectedCircleId = null),
          initialCameraPosition: CameraPosition(
            target: _currentUserPosition ?? const LatLng(0, 0),
            zoom: 14,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _markers.values.toSet(),
          circles: {
            ..._buildGeofenceCircles(),
            ..._deviceCircles.values.toSet(),
          },
          polylines: _polylines.values.toSet(),
        ),

        // Info card overlay
        if (_selectedCircleId != null && _circleInfo[_selectedCircleId!] != null)
          Positioned(
            top: 80, // moved lower to avoid time filter overlap
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Builder(
                        builder: (context) {
                          final info = _circleInfo[_selectedCircleId!]!;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pets, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      info.dogName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black, // ensure visible
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTimestamp(info.timestampIso),
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                icon: const Icon(Icons.close, size: 18),
                                splashRadius: 18,
                                onPressed: () => setState(() => _selectedCircleId = null),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Time filter bar
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Material(
                elevation: 3,
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: const Text('1h'),
                        selected: _timeFilter == TimeFilterPreset.lastHour,
                        onSelected: (_) => _setTimePreset(TimeFilterPreset.lastHour),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('6h'),
                        selected: _timeFilter == TimeFilterPreset.last6h,
                        onSelected: (_) => _setTimePreset(TimeFilterPreset.last6h),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('24h'),
                        selected: _timeFilter == TimeFilterPreset.last24h,
                        onSelected: (_) => _setTimePreset(TimeFilterPreset.last24h),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Today'),
                        selected: _timeFilter == TimeFilterPreset.today,
                        onSelected: (_) => _setTimePreset(TimeFilterPreset.today),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _timeFilter == TimeFilterPreset.all,
                        onSelected: (_) => _setTimePreset(TimeFilterPreset.all),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(
                          _timeFilter == TimeFilterPreset.custom && _filterStart != null && _filterEnd != null
                              ? '${_filterStart!.month}/${_filterStart!.day} ${_filterStart!.hour.toString().padLeft(2, '0')}:${_filterStart!.minute.toString().padLeft(2, '0')} - ${_filterEnd!.month}/${_filterEnd!.day} ${_filterEnd!.hour.toString().padLeft(2, '0')}:${_filterEnd!.minute.toString().padLeft(2, '0')}'
                              : 'Custom',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: _pickCustomRange,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Existing action buttons (bottom-left)
        Positioned(
          bottom: 16,
          left: 16,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoomDogFab',
                  onPressed: _zoomToSelectedDog,
                  tooltip: 'Zoom to Selected Dog',
                  child: const Icon(Icons.pets),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'toggleTrackingFab',
                  onPressed: _toggleLocationTracking,
                  tooltip: _isTracking ? 'Tracking Enabled' : 'Tracking Disabled',
                  backgroundColor: _isTracking ? null : Colors.white,
                  child: Icon(
                    _isTracking ? Icons.location_on : Icons.location_off,
                    color: _isTracking ? Colors.blue : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'centerCityHallFab',
                  onPressed: _moveCameraToCityHall,
                  tooltip: 'Center on City Hall',
                  child: const Icon(Icons.location_city),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}