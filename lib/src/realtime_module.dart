import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'realtime_channel.dart';

import 'package:web_socket_channel/io.dart'; 

/// Xaaladaha xiriirka WebSocket
enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

class SuperAIBRealtime {
  final String _baseUrl;
  final String _projectRef;
  final String _apiKey;
  String? _userID;

  WebSocketChannel? _channel;
  RealtimeStatus _status = RealtimeStatus.disconnected;
  
  // Channels manager: Ku xafid qolalka firfircoon halkan
  final Map<String, SuperAIBRealtimeChannel> _activeChannels = {};
  
  // Status Stream: Si UI-gu u ogaado haddii la xiran yahay iyo haddii kale
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  Stream<RealtimeStatus> get onStatusChange => _statusController.stream;

  // Reconnection Logic
  int _retryAttempts = 0;
  Timer? _reconnectTimer;

  SuperAIBRealtime(this._baseUrl, this._projectRef, this._apiKey);

  // 🚀 1. IDENTITY MANAGEMENT
  void setUserID(String? id) {
    if (_userID == id) return;
    _userID = id;
    print("🆔 SuperAIB Realtime: Identity set to [$id]");

    if (_status == RealtimeStatus.connected) {
      _reconnectImmediately();
    }
  }

  Future<void> connect() async {
  if (_status == RealtimeStatus.connected || _status == RealtimeStatus.connecting) return;

  _status = RealtimeStatus.connecting;
  _statusController.add(_status);

  // 🚀 MUHIIM: Hubi in port-ka uu yahay 8080 iyo path-ka saxda ah
  // ws://localhost:8080/api/v1/ws/PROJECT_ID
  final String wsUrl = "$_baseUrl/ws/$_projectRef?api_key=$_apiKey${_userID != null ? "&user_id=$_userID" : ""}";

  print("🌐 SDK: Trying to connect to $wsUrl");

  try {
    _channel = IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      pingInterval: Duration(seconds: 10),
    );

    // Kani waa muhiim si loo hubiyo inuu xiriirku dhashay
    _status = RealtimeStatus.connected;
    _statusController.add(_status);
    print("✅ SDK: WebSocket Connected Successfully");

    _reSubscribeToAll();

    _channel!.stream.listen(
      (message) {
        print("📩 SDK: Received raw message: $message");
        _onMessageReceived(message);
      },
      onDone: () {
        print("🔌 SDK: Connection Closed");
        _handleDisconnect();
      },
      onError: (err) {
        print("❌ SDK: Connection Error: $err");
        _handleDisconnect();
      },
    );
  } catch (e) {
    print("❌ SDK: Catch error: $e");
    _handleDisconnect();
  }
}
  // 🚀 3. CHANNEL SYSTEM
  SuperAIBRealtimeChannel channel(String name) {
    if (_activeChannels.containsKey(name)) {
      return _activeChannels[name]!;
    }
    final newChannel = SuperAIBRealtimeChannel(name, this);
    _activeChannels[name] = newChannel;
    return newChannel;
  }

  // 🚀 4. MESSAGE DISTRIBUTOR (Internal)
  void _onMessageReceived(dynamic rawMessage) {
    try {
      final data = json.decode(rawMessage);
      final String? channelName = data['channel'];
      
      // A. U dir fariinta qolka ay ku socoto
      if (channelName != null && _activeChannels.containsKey(channelName)) {
        _activeChannels[channelName]!.handleInternalMessage(data);
      }

      // B. Presence Handling (Haddii uu yahay Global Event)
      final String? eventType = data['event_type'];
      if (eventType != null && eventType.startsWith("PRESENCE_")) {
        for (var channel in _activeChannels.values) {
          channel.handleInternalMessage(data);
        }
      }
    } catch (e) {
      print("⚠️ Realtime Parsing Error: $e");
    }
  }

  // 🚀 5. RESILIENCE (Auto-Reconnection)
  void _handleDisconnect() {
    if (_status == RealtimeStatus.disconnected) return;

    _status = RealtimeStatus.reconnecting;
    _statusController.add(_status);
    _reconnectTimer?.cancel();
    
    int waitTime = (1 << _retryAttempts); 
    if (waitTime > 30) waitTime = 30;

    print("⚠️ SuperAIB Realtime: Link lost. Retrying in $waitTime seconds...");

    _reconnectTimer = Timer(Duration(seconds: waitTime), () {
      _retryAttempts++;
      connect();
    });
  }

  void _reconnectImmediately() {
    disconnect();
    connect();
  }

  void _reSubscribeToAll() {
    for (var channel in _activeChannels.values) {
      channel.subscribe();
    }
  }

  void sendCommand(Map<String, dynamic> data) {
    if (_status == RealtimeStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(data));
      } catch (e) {
        print("❌ Failed to send command: $e");
      }
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _status = RealtimeStatus.disconnected;
    _statusController.add(_status);
  }

  // Getters
  bool get isConnected => _status == RealtimeStatus.connected;
}