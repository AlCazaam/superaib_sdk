import 'dart:async';
import 'package:dio/dio.dart';
import 'realtime_module.dart';

class SuperAIBRealtimeChannel {
  final String name;
  final String channelId;
  final SuperAIBRealtime _module;
  final Dio _dio;

  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  Timer? _pollingTimer;
  DateTime? _lastFetchTime;

  SuperAIBRealtimeChannel(this.name, this.channelId, this._module, this._dio);

  // 🚀 1. SUBSCRIBE (HTTP Polling Fallback)
  void subscribe() {
    if (_pollingTimer != null) return;
    print("📡 SDK: Subscribing to [$name] (Polling Mode Started)");
    _lastFetchTime = DateTime.now();

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchNewEvents();
    });
  }

  // 🚀 2. BROADCAST (HTTP POST)
  Future<void> broadcast({required String event, required Map<String, dynamic> payload}) async {
    try {
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

  // 🚀 3. LISTEN
  void on(String eventName, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(eventName)) {
      _eventListeners[eventName] = [];
    }
    _eventListeners[eventName]!.add(callback);
  }

  // 🚀 4. HANDLE INTERNAL MESSAGE (FIXED ✅)
  // Kani waa kan uu RealtimeModule u yeerayo marka WebSocket fariin keeno
  void handleInternalMessage(Map<String, dynamic> data) {
    final String? eventType = data['event_type'];
    final dynamic payload = data['payload'];

    if (eventType != null && _eventListeners.containsKey(eventType)) {
      for (var callback in _eventListeners[eventType]!) {
        callback(payload);
      }
    }
  }

  // 🛠️ INTERNAL POLLING
  Future<void> _fetchNewEvents() async {
    try {
      final response = await _dio.get('projects/${_module.projectRef}/realtime/channels/$channelId/events');
      if (response.statusCode == 200) {
        final List<dynamic> events = response.data['data'] ?? [];
        for (var e in events) {
          final DateTime createdAt = DateTime.parse(e['created_at']);
          if (_lastFetchTime == null || createdAt.isAfter(_lastFetchTime!)) {
            handleInternalMessage(e); // Isticmaal isla mishiinka kore
            _lastFetchTime = createdAt;
          }
        }
      }
    } catch (e) { /* ignore polling errors */ }
  }

  void unsubscribe() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}