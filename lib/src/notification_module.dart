import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'realtime_module.dart';

class SuperAIBNotifications {
  final Dio _dio;
  final String _projectRef;
  final SuperAIBRealtime _realtime;

  SuperAIBNotifications(this._dio, this._projectRef, this._realtime);

  // 🚀 1. REGISTER DEVICE: pgAdmin (device_tokens)
  Future<void> registerDevice({required String token, required String userId, String? platform}) async {
    try {
      String detectedPlatform = platform ?? (kIsWeb ? "web" : (Platform.isAndroid ? "android" : "ios"));
      await _dio.post('/projects/$_projectRef/notifications/register', data: {
        'token': token,
        'platform': detectedPlatform,
        'user_id': userId,
      });
      print("✅ SDK Notifications: Device token registered.");
    } catch (e) {
      print("❌ SDK Notifications Error: $e");
    }
  }

  // 🚀 2. SEND BROADCAST (Dashboard Trigger)
  Future<void> sendBroadcast({required String title, required String body}) async {
    try {
      await _dio.post('/projects/$_projectRef/notifications/broadcast', data: {
        'title': title,
        'body': body,
      });
      print("🚀 SDK Notifications: Broadcast sent to all.");
    } catch (e) {
      print("❌ SDK Notifications Error: Broadcast failed.");
    }
  }

  // 🚀 3. ON NOTIFICATION RECEIVED (THE GLOBAL LISTENER ✅)
  // Kani waa mishiinka ugu Professional-ka ah. Wuxuu dhageysanayaa WebSocket Stream-ka guud.
 // 🚀 LISTEN FOR LIVE NOTIFICATIONS (THE GLOBAL LISTENER)
  void onNotificationReceived(Function(Map<String, dynamic>) callback) {
    print("📡 SDK: Global Notification Listener is now ACTIVE.");

    // A. Hubi xiriirka
    if (!_realtime.isConnected) {
      _realtime.connect(); 
    }

    // B. Dhageyso dhacdo kasta oo ka timaada WebSocket-ka guud
    _realtime.onMessageReceived((rawMessage) {
      try {
        // 🛠️ MUHIIM: WebSocket fariintiisu waa String, markaa marka hore decode dheh
        final Map<String, dynamic> data = json.decode(rawMessage.toString());
        
        // C. Haddii fariintu tahay PUSH_NOTIFICATION, u sii qofka
        if (data['event_type'] == "PUSH_NOTIFICATION") {
          print("🎯 SDK: Global Notification Caught from Stream!");
          
          // Payload-ka u dhiib App-ka
          callback(Map<String, dynamic>.from(data['payload']));
        }
      } catch (e) {
        // Iska dhaaf fariimaha aan ahayn Notifications-ka (sida Chat-ka)
      }
    });
  }

  // 🚀 4. FETCH HISTORY
  Future<List<dynamic>> getHistory() async {
    try {
      final res = await _dio.get('/projects/$_projectRef/notifications/history');
      return res.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}