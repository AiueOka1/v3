import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> initialize({
    required VoidCallback onOpenAlerts,
  }) async {
    if (_inited) return;
    _inited = true;

    // iOS-specific initialization
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit, // Add iOS settings
    );
    
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        onOpenAlerts();
      },
    );

    // Request permissions for both platforms
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true, 
      badge: true, 
      sound: true,
      provisional: false, // iOS-specific
      criticalAlert: false, // iOS-specific
      announcement: false, // iOS-specific
    );

    // Check permission status
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Request Android 13+ notifications permission
    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Request iOS permissions explicitly
    if (Platform.isIOS) {
      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Configure background message handling
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onOpenAlerts();
    });

    // Handle notification when app is terminated
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onOpenAlerts();
    }

    // Get FCM token for debugging
    final String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Save token to Firestore
    if (token != null) {
      await _saveFcmToken(token);
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((String token) {
      print('FCM Token refreshed: $token');
      _saveFcmToken(token);
    });
  }

  // iOS-specific callback for local notifications when app is in foreground
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    // Handle iOS local notification when app is in foreground
    print('iOS Local notification received: $title - $body');
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'PawTech';
    final body = message.notification?.body ?? 'New notification';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'FCM Messages',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    // Add iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails, // Add iOS details
    );

    await _local.show(
      message.hashCode,
      title,
      body,
      details,
      payload: message.data.toString(),
    );
  }

  // Save FCM token to Firestore
  static Future<void> _saveFcmToken(String token) async {
    try {
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
        print('FCM token saved to Firestore');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Platform-specific method to handle background messages
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    // Handle background message processing here
  }

  // Get FCM token (works on both platforms)
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic (works on both platforms)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic (works on both platforms)
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}