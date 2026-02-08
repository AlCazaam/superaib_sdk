import 'dart:io';

import 'package:dio/dio.dart';
import 'realtime_module.dart';

class SuperAIBNotifications {
  final Dio _dio;
  final String _projectRef;
  final SuperAIBRealtime _realtime;

  SuperAIBNotifications(this._dio, this._projectRef, this._realtime);



  // 🚀 2. SEND BROADCAST
  Future<void> sendBroadcast({
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    Map<String, dynamic>? customData,
  }) async {
    try {
      await _dio.post(
        '/projects/$_projectRef/notifications/broadcast',
        data: {
          'title': title,
          'body': body,
          'image_url': imageUrl,
          'deep_link': deepLink,
          'custom_data': customData ?? {},
        },
      );
    } catch (e) {
      print("❌ Notifications Error: $e");
    }
  }
  // 🚀 1. ENABLE PUSH (AUTOMATIC REGISTRATION)
  // Kani wuxuu si otomaatig ah u garanayaa Platform-ka (Android/iOS)
  Future<void> enablePush({required String token, required String userId}) async {
    String platform = "web";
    if (Platform.isAndroid) platform = "android";
    if (Platform.isIOS) platform = "ios";

    print("📱 SDK: Auto-registering device for $platform...");
    
    return registerDevice(
      token: token,
      platform: platform,
      userId: userId,
    );
  }

  // 🚀 2. REGISTER DEVICE (Manual)
  Future<void> registerDevice({
    required String token,
    required String platform, 
    required String userId,
  }) async {
    try {
      await _dio.post(
        '/projects/$_projectRef/notifications/register',
        data: {
          'token': token,
          'platform': platform,
          'user_id': userId,
        },
      );
      print("✅ Notifications: Device Token saved in pgAdmin!");
    } catch (e) {
      print("❌ Notifications Error: $e");
    }
  }


  // 🚀 3. LISTEN FOR LIVE NOTIFICATIONS (FIXED ✅)
  // Waxaan ku darnay 'async' iyo 'await' halkan
  void onNotificationReceived(Function(Map<String, dynamic>) callback) async {
    _realtime.connect(); 
    
    print("📡 SDK: Setting up live notification listener...");

    // 🛠️ XALKA: Waa inaan sugnaa inta channel-ka laga soo abuurayo database-ka
    final systemChannel = await _realtime.channel("project_system_events");
    
    if (systemChannel != null) {
      systemChannel.subscribe();
      
      systemChannel.on("PUSH_NOTIFICATION", (payload) {
        print("🔔 SDK: New Notification Received Live!");
        callback(Map<String, dynamic>.from(payload));
      });
    } else {
      print("❌ SDK Error: Could not initialize notification channel.");
    }
  }

  // 🚀 4. HISTORY
  Future<List<dynamic>> getHistory() async {
    try {
      final res = await _dio.get('/projects/$_projectRef/notifications/history');
      return res.data['data'];
    } catch (e) {
      throw Exception("❌ Notifications: Failed to fetch history: $e");
    }
  }
}