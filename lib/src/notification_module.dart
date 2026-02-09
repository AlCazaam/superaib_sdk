import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SuperAIBNotifications {
  final Dio _dio;
  final String _projectRef;

  Timer? _pollingTimer;
  String? _lastNotificationId; // 👈 Kani wuxuu ka hortagayaa in fariin la arkay soo laabato

  SuperAIBNotifications(this._dio, this._projectRef);

  // 🚀 1. REGISTER DEVICE (pgAdmin)
  // Wuxuu kaydiyaa Token-ka, Platform-ka, iyo haddii uu qofku Switch-ka u furan yahay (Enabled).
  Future<void> registerDevice({
    required String token,
    required String userId,
    required bool enabled, // 👈 Kani wuxuu maamulaa On/Off status-ka pgAdmin
    String? platform,      // Optional: Haddii aan la soo dhiibin, SDK ayaa garanaya
  }) async {
    try {
      // 📱 1. Gari Platform-ka si otomaatig ah (Logic-ga caalamiga ah)
      String detectedPlatform = platform ?? (kIsWeb ? "web" : (Platform.isAndroid ? "android" : "ios"));

      print("📱 SDK: Syncing device token with pgAdmin (Enabled: $enabled)...");

      // 📡 2. U dir Backend-ka
      final response = await _dio.post(
        '/projects/$_projectRef/notifications/register',
        data: {
          'token': token,
          'platform': detectedPlatform,
          'user_id': userId,
          'enabled': enabled, // 👈 U gudbi status-ka dhabta ah
        },
      );

      if (response.statusCode == 200) {
        print("✅ SDK: Device successfully registered/updated in pgAdmin ($detectedPlatform)");
      }
    } catch (e) {
      print("❌ SDK Error: Device registration failed: $e");
    }
  }
  // 🚀 2. SEND BROADCAST
  Future<void> sendBroadcast({required String title, required String body}) async {
    try {
      await _dio.post('/projects/$_projectRef/notifications/broadcast', data: {
        'title': title,
        'body': body,
      });
      print("✅ SDK: Broadcast sent via HTTP.");
    } catch (e) {
      print("❌ SDK Error: Broadcast failed.");
    }
  }

  // 🚀 3. LISTEN FOR NOTIFICATIONS (HTTP POLLING VERSION ✅)
  // Kani waa mishiinka adiga kugu haboon sxb (Passive & Stable)
// 🚀 3. LISTEN FOR NOTIFICATIONS (POLLING WITH STATUS CHECK ✅)
  void onNotificationReceived(Function(Map<String, dynamic>) callback) {
    print("📡 SDK: Global HTTP Notification Listener is now ACTIVE.");
    
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final history = await getHistory();
        if (history.isNotEmpty) {
          final latest = history.first; // Fariinta ugu dambaysa
          final String currentId = latest['id'].toString();
          final String status = latest['status'].toString(); // 👈 Hel status-ka

          // 🛠️ XALKA MUCJISADA AH:
          // KALIYA muuji haddii status-ku yahay 'sent'. 
          // Haddii uu yahay 'pending', iska dhaaf ilaa waqtigeeda laga gaaro!
          if (status == 'sent') {
            if (_lastNotificationId == null) {
              _lastNotificationId = currentId;
            } else if (_lastNotificationId != currentId) {
              _lastNotificationId = currentId;
              print("🔔 SDK: New SENT notification detected!");
              callback(Map<String, dynamic>.from(latest));
            }
          } else {
            // Fariintu waa pending, iska illow hadda
            print("⏳ SDK: Waiting for scheduled notification [ID: $currentId] to trigger...");
          }
        }
      } catch (e) { }
    });
  }
// 🚀 GET REGISTRATION STATUS
  Future<Map<String, dynamic>> getRegistrationStatus(String userId) async {
    try {
      final res = await _dio.get('/projects/$_projectRef/notifications/status/$userId');
      return res.data['data'];
    } catch (e) {
      return {'enabled': false};
    }
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


  void stopListening() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}