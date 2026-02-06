import 'dart:async';

class SuperAIBRealtimeChannel {
  final String name;
  final dynamic _module; // SuperAIBRealtime

  // Callbacks for events: event_name -> list of functions
  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  
  // Presence Stream
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();

  SuperAIBRealtimeChannel(this.name, this._module);

  // 🚀 2. SUBSCRIBE: Bilaw dhageysiga qolka
  void subscribe() {
    _module.sendCommand({
      "action": "SUBSCRIBE",
      "channel": name,
    });
  }

  // 🚀 3. EVENT LISTENERS: .on('new_message', (data) => ...)
  void on(String eventName, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(eventName)) {
      _eventListeners[eventName] = [];
    }
    _eventListeners[eventName]!.add(callback);
  }

  // 🚀 4. BROADCASTING: .broadcast(event: 'typing', payload: {...})
  void broadcast({required String event, required Map<String, dynamic> payload}) {
    _module.sendCommand({
      "action": "BROADCAST",
      "channel": name,
      "event": event,
      "payload": payload,
    });
  }

  // 🚀 5. PRESENCE: Dhageysiga dadka soo galaya/baxaya
  Stream<Map<String, dynamic>> presence() {
    return _presenceController.stream;
  }

  // INTERNAL: Marka fariin dhab ah laga soo helo WebSocket-ka
  void handleInternalMessage(Map<String, dynamic> data) {
    final String eventType = data['event_type'];
    final dynamic payload = data['payload'];

    // A. Haddii ay tahay fariin caadi ah
    if (_eventListeners.containsKey(eventType)) {
      for (var callback in _eventListeners[eventType]!) {
        callback(payload);
      }
    }

    // B. Haddii ay tahay Presence (Join/Leave)
    if (eventType.startsWith("PRESENCE_")) {
      _presenceController.add({
        "event": eventType.replaceFirst("PRESENCE_", ""),
        "user_id": data['user_id'],
        "timestamp": data['timestamp'],
      });
    }
  }

  void unsubscribe() {
    _module.sendCommand({
      "action": "UNSUBSCRIBE",
      "channel": name,
    });
  }
}