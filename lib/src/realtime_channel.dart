import 'dart:async';
import 'package:dio/dio.dart';
import 'realtime_module.dart';

class SuperAIBRealtimeChannel {
  final String name;
  final String channelId;
  final SuperAIBRealtime _module;
  final Dio _dio;

  // Listeners iyo Polling
  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  Timer? _pollingTimer;
  DateTime? _lastFetchTime;

  SuperAIBRealtimeChannel(this.name, this.channelId, this._module, this._dio);

  // 🚀 1. SUBSCRIBE (Starts HTTP Polling)
  void subscribe() {
    if (_pollingTimer != null) return;
    
    print("📡 SDK: Subscribing to [$name] (Polling Mode Started)");
    _lastFetchTime = DateTime.now(); // Kaliya soo qaado fariimaha hadda kadib imaanaya

    // 2-dii ilbiriqsiba mar soo hubi fariimo cusub
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchNewEvents();
    });
  }

  // 🚀 2. BROADCAST (HTTP POST - 100% Guaranteed pgAdmin Save)
  Future<void> broadcast({required String event, required Map<String, dynamic> payload}) async {
    try {
      print("📤 SDK: Broadcasting via HTTP...");
      await _dio.post(
        'projects/${_module.projectRef}/realtime/channels/$channelId/events',
        data: {
          'event_type': event,
          'payload': payload,
        },
      );
      print("✅ SDK: Message saved to pgAdmin!");
    } catch (e) {
      print("❌ SDK Error: Broadcast failed: $e");
    }
  }

  // 🚀 3. LISTEN (On Event Received)
  void on(String eventName, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(eventName)) {
      _eventListeners[eventName] = [];
    }
    _eventListeners[eventName]!.add(callback);
  }

  // 🛠️ INTERNAL: Fetch events from pgAdmin
  Future<void> _fetchNewEvents() async {
    try {
      final response = await _dio.get(
        'projects/${_module.projectRef}/realtime/channels/$channelId/events'
      );

      if (response.statusCode == 200) {
        final List<dynamic> events = response.data['data'] ?? [];
        
        for (var e in events) {
          final DateTime createdAt = DateTime.parse(e['created_at']);
          
          // Kaliya process gareey haddii ay fariintu tahay mid cusub
          if (_lastFetchTime == null || createdAt.isAfter(_lastFetchTime!)) {
            final String eventType = e['event_type'];
            final dynamic payload = e['payload'];

            if (_eventListeners.containsKey(eventType)) {
              for (var callback in _eventListeners[eventType]!) {
                callback(payload);
              }
            }
            _lastFetchTime = createdAt; // Update last fetch time
          }
        }
      }
    } catch (e) {
      // Hilmad polling error si aysan u buuxin terminal-ka
    }
  }

  void unsubscribe() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print("🔌 SDK: Unsubscribed from [$name]");
  }
}