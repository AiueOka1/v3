// Test script to demonstrate the device assignment fix
// Run this in your main app to see the device assignments in action

import 'package:firebase_database/firebase_database.dart';

class DeviceAssignmentTest {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Check the current device assignments in realtime database
  static Future<void> checkDeviceAssignments() async {
    try {
      print('🔍 Checking device assignments in realtime database...');
      
      final dataSnapshot = await _database.child('data').get();
      
      if (!dataSnapshot.exists) {
        print('❌ No data found in realtime database');
        return;
      }
      
      final devicesData = dataSnapshot.value as Map<dynamic, dynamic>;
      
      print('📱 Found ${devicesData.length} devices:');
      
      devicesData.forEach((deviceId, deviceData) {
        if (deviceData is Map) {
          final dogId = deviceData['dogId'] as String?;
          final deviceName = deviceData['deviceName'] as String?;
          
          print('  Device: $deviceId');
          print('    Name: $deviceName');
          print('    Dog ID: ${dogId ?? "Not assigned"}');
          
          if (deviceData.containsKey('lat') && deviceData.containsKey('lon')) {
            print('    Location: ${deviceData['lat']}, ${deviceData['lon']}');
          }
          
          print('');
        }
      });
      
      // Show summary of assignments
      final assignedDevices = devicesData.entries
          .where((entry) => entry.value is Map && (entry.value as Map).containsKey('dogId'))
          .length;
      
      print('📊 Summary:');
      print('  Total devices: ${devicesData.length}');
      print('  Assigned devices: $assignedDevices');
      print('  Unassigned devices: ${devicesData.length - assignedDevices}');
      
    } catch (e) {
      print('❌ Error checking device assignments: $e');
    }
  }

  /// Simulate assigning a device to a dog (for testing)
  static Future<bool> simulateDeviceAssignment(String deviceId, String dogId) async {
    try {
      print('🔧 Simulating assignment of $deviceId to dog $dogId...');
      
      // Check if device exists
      final deviceSnapshot = await _database.child('data/$deviceId').get();
      if (!deviceSnapshot.exists) {
        print('❌ Device $deviceId does not exist');
        return false;
      }
      
      // Update the device with the dog ID
      await _database.child('data/$deviceId').update({'dogId': dogId});
      
      print('✅ Successfully assigned $deviceId to dog $dogId');
      return true;
      
    } catch (e) {
      print('❌ Error simulating device assignment: $e');
      return false;
    }
  }

  /// Clear all device assignments (for testing)
  static Future<void> clearAllAssignments() async {
    try {
      print('🧹 Clearing all device assignments...');
      
      final dataSnapshot = await _database.child('data').get();
      
      if (!dataSnapshot.exists) {
        print('❌ No data found in realtime database');
        return;
      }
      
      final devicesData = dataSnapshot.value as Map<dynamic, dynamic>;
      
      for (final deviceId in devicesData.keys) {
        await _database.child('data/$deviceId/dogId').remove();
      }
      
      print('✅ All device assignments cleared');
      
    } catch (e) {
      print('❌ Error clearing assignments: $e');
    }
  }

  /// Show instructions for fixing the device assignment issue
  static void showFixInstructions() {
    print('''
🔧 Device Assignment Fix Instructions:

Problem: Dogs show "Add GPS" even when devices are assigned in realtime database.

Solution implemented:
1. Updated DogProvider.fetchDogs() to check realtime database for device assignments
2. Added _checkAndUpdateDeviceAssignments() method
3. Updated Dog model to properly handle deviceId field
4. Added debug screen to view assignments

To test the fix:
1. Check current assignments: DeviceAssignmentTest.checkDeviceAssignments()
2. Open the app and navigate to Profile -> Device Assignment Debug
3. Refresh device assignments if needed
4. Check that dogs with assigned devices now show "GPS" instead of "Add GPS"

Your current realtime database structure:
/data
  /DEVICE001
    deviceName: "BuddyTracker"
    dogId: "Siw95qwVc9PacJvLJ1Kh"
    locations: {...}
  /DEVICE002
    deviceName: "BuddyTracker" 
    dogId: "4VSGGml88wa5GFznYLvz"
    lat: 14.7570423
    lon: 120.963836
  ...

The fix ensures that when dogs are loaded, the app checks if any device has that dog's ID assigned.
    ''');
  }
}

/// Example usage function
Future<void> runDeviceAssignmentTest() async {
  DeviceAssignmentTest.showFixInstructions();
  await DeviceAssignmentTest.checkDeviceAssignments();
}
