import 'dart:async';
import 'realtime_module.dart';

class SuperAIBRealtimeChannel {
  final String name;
  final SuperAIBRealtime _module;

  // Listeners loogu talagalay Events (e.g. NEW_MESSAGE)
  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  
  // Presence Stream (Optional)
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();

  SuperAIBRealtimeChannel(this.name, this._module);

  // 🚀 1. SUBSCRIBE: Kani ayaa fariinta u diraya Server-ka si pgAdmin u keydiyo
  void subscribe() {
    print("📡 SDK: Subscribing to channel [$name]");
    _module.sendCommand({
      "action": "SUBSCRIBE",
      "channel": name,
    });
  }

  // 🚀 2. BROADCAST: U dir fariin Live ah (Tani waxay gashaa realtime_events)
  void broadcast({required String event, required Map<String, dynamic> payload}) {
    _module.sendCommand({
      "action": "BROADCAST",
      "channel": name,
      "event": event,
      "payload": payload,
    });
  }

  // 🚀 3. LISTEN: Dhageyso fariimaha soo dhacaya
  void on(String eventName, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(eventName)) {
      _eventListeners[eventName] = [];
    }
    _eventListeners[eventName]!.add(callback);
  }

  // INTERNAL: Waxaa waca RealtimeModule marka xog timaado
  void handleInternalMessage(Map<String, dynamic> data) {
    final String? eventType = data['event_type'];
    final dynamic payload = data['payload'];

    if (eventType == null) return;

    // A. Haddii ay tahay Custom Event (e.g. NEW_MESSAGE)
    if (_eventListeners.containsKey(eventType)) {
      for (var callback in _eventListeners[eventType]!) {
        callback(payload);
      }
    }

    // B. Haddii ay tahay Presence
    if (eventType.startsWith("PRESENCE_")) {
      _presenceController.add({
        "event": eventType.replaceFirst("PRESENCE_", ""),
        "user_id": data['sender_id'],
        "timestamp": data['timestamp'],
      });
    }
  }

  Stream<Map<String, dynamic>> presence() => _presenceController.stream;

  void unsubscribe() {
    _module.sendCommand({"action": "UNSUBSCRIBE", "channel": name});
  }
}