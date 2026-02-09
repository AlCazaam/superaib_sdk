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
  Future<void> registerDevice({required String token, required String userId, String? platform}) async {
    try {
      String detectedPlatform = platform ?? (kIsWeb ? "web" : (Platform.isAndroid ? "android" : "ios"));
      await _dio.post('/projects/$_projectRef/notifications/register', data: {
        'token': token,
        'platform': detectedPlatform,
        'user_id': userId,
      });
      print("✅ SDK: Device Token registered.");
    } catch (e) {
      print("❌ SDK Error: Registration failed.");
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
  void onNotificationReceived(Function(Map<String, dynamic>) callback) {
    print("📡 SDK: Global HTTP Notification Listener is now ACTIVE.");
    
    // Haddii uu hore u socday, iska xir
    _pollingTimer?.cancel();

    // 2-dii ilbiriqsiba mar soo eeg pgAdmin fariimihii ugu dambeeyay
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final history = await getHistory();
        if (history.isNotEmpty) {
          final latest = history.first; // Fariinta ugu dambaysa
          final String currentId = latest['id'].toString();

          // 🛠️ XALKA: Kaliya muuji haddii ID-gan uu yahay mid cusub!
          if (_lastNotificationId == null) {
            _lastNotificationId = currentId; // Marka ugu horreysa kaliya xasuuso
          } else if (_lastNotificationId != currentId) {
            _lastNotificationId = currentId; // Update last seen
            print("🔔 SDK: New Notification detected via Polling!");
            callback(Map<String, dynamic>.from(latest));
          }
        }
      } catch (e) {
        // Silent error to avoid terminal spam
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

  void stopListening() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}