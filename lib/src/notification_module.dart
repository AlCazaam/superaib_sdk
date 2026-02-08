import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'realtime_module.dart';

class SuperAIBNotifications {
  final Dio _dio;
  final String _projectRef;
  final SuperAIBRealtime _realtime;

  SuperAIBNotifications(this._dio, this._projectRef, this._realtime);

  // 🚀 1. ENABLE PUSH (AUTOMATIC REGISTRATION)
  // Kani wuxuu si otomaatig ah u garanayaa Platform-ka (Android/iOS)
  Future<void> enablePush({required String token, required String userId}) async {
    print("📱 SDK: Auto-registering device for push notifications...");
    
    return registerDevice(
      token: token,
      userId: userId,
    );
  }

  // 🚀 2. REGISTER DEVICE: Kani waa kan pgAdmin xogta ku ridaya (device_tokens table)
  Future<void> registerDevice({
    required String token,
    required String userId,
    String? platform, // Haddii aan la soo dirin, SDK ayaa garanaya
  }) async {
    try {
      // 📱 Gari Platform-ka si otomaatig ah hadii aan la soo dhiibin
      String detectedPlatform = platform ?? (kIsWeb ? "web" : (Platform.isAndroid ? "android" : "ios"));

      await _dio.post(
        '/projects/$_projectRef/notifications/register',
        data: {
          'token': token,
          'platform': detectedPlatform,
          'user_id': userId,
        },
      );
      print("✅ SDK: Device Token saved in pgAdmin ($detectedPlatform)");
    } catch (e) {
      print("❌ SDK Error: Device registration failed: $e");
    }
  }

  // 🚀 3. SEND BROADCAST: U dir fariin qof kasta oo App-ka haysta
  Future<void> sendBroadcast({
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    Map<String, dynamic>? customData,
  }) async {
    try {
      print("📤 SDK: Sending broadcast notification...");
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
      print("✅ SDK: Broadcast processed by server.");
    } catch (e) {
      print("❌ SDK Error: Broadcast failed: $e");
    }
  }

  // 🚀 4. LISTEN FOR LIVE NOTIFICATIONS
  // Marka Dashboard-ka laga soo diro, fariintu halkan ayay ka soo baxaysaa si Live ah
  void onNotificationReceived(Function(Map<String, dynamic>) callback) async {
    print("📡 SDK: Setting up live notification listener...");

    // Hubi in Realtime uu xiran yahay
    _realtime.connect(); 

    // 🛠️ Waa inaan sugnaa inta channel-ka laga soo abuurayo database-ka (HTTP)
    final systemChannel = await _realtime.channel("project_system_events");
    
    if (systemChannel != null) {
      // Bilow dhageysiga
      systemChannel.subscribe();
      
      systemChannel.on("PUSH_NOTIFICATION", (payload) {
        print("🔔 SDK: New Notification Received Live!");
        callback(Map<String, dynamic>.from(payload));
      });
    } else {
      print("❌ SDK Error: Could not initialize notification channel.");
    }
  }

  // 🚀 5. HISTORY: Ka soo qaado fariimihii hore loo diray pgAdmin
  Future<List<dynamic>> getHistory() async {
    try {
      final res = await _dio.get('/projects/$_projectRef/notifications/history');
      return res.data['data'] ?? [];
    } catch (e) {
      print("❌ SDK Error: Failed to fetch history: $e");
      return [];
    }
  }
}