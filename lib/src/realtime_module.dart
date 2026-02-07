import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'realtime_channel.dart';

enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

class SuperAIBRealtime {
  final String _baseUrl; // Tusaale: http://localhost:8080/api/v1
  final String _projectRef;
  final String _apiKey;
  String? _userID;

  WebSocketChannel? _channel;
  RealtimeStatus _status = RealtimeStatus.disconnected;
  
  final Map<String, SuperAIBRealtimeChannel> _activeChannels = {};
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  Stream<RealtimeStatus> get onStatusChange => _statusController.stream;

  int _retryAttempts = 0;
  Timer? _reconnectTimer;

  SuperAIBRealtime(this._baseUrl, this._projectRef, this._apiKey);

  // 🚀 CONNECTION ENGINE (FIXED & POWERFUL)
// 🚀 CONNECTION ENGINE (STRICT PLAIN-TEXT VERSION)
  Future<void> connect() async {
    // 1. Hubi haddii uu horay u xirnaa
    if (_status == RealtimeStatus.connected || _status == RealtimeStatus.connecting) return;

    _status = RealtimeStatus.connecting;
    _statusController.add(_status);

    try {
      // 2. URL Sanitization: Ka saar '/' dhamaadka hadii uu jiro
      String cleanBase = _baseUrl.endsWith('/') 
          ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
      
      String wsUrl;

      // 3. Protocol Switcher: http -> ws, https -> wss
      if (cleanBase.startsWith('https://')) {
        wsUrl = cleanBase.replaceFirst('https://', 'wss://');
      } else if (cleanBase.startsWith('http://')) {
        wsUrl = cleanBase.replaceFirst('http://', 'ws://');
      } else {
        wsUrl = cleanBase; // Haddii uu horay u ahaa ws/wss
      }

      // 4. Final Path Assembly: /ws/{project_id}?api_key={key}&user_id={id}
      final String finalWsUrl = "$wsUrl/ws/$_projectRef?api_key=$_apiKey" + 
                           (_userID != null ? "&user_id=$_userID" : "");

      print("🌐 SDK: Connecting to WebSocket -> $finalWsUrl");

      // 5. 🚀 THE NUCLEAR FIX: 
      // Waxaan ku xiraynaa IOWebSocketChannel anagoo si xoog ah u tirtirayna 
      // Sec-WebSocket-Extensions si aan u joojino RSV1/Compression Error.
      _channel = IOWebSocketChannel.connect(
        Uri.parse(finalWsUrl),
        pingInterval: const Duration(seconds: 10),
        // 🛡️ Kani waa furaha guusha Simulator-ka:
        headers: {
          'Sec-WebSocket-Extensions': '', // Force disable compression extensions
        },
      );

      // 6. Update Status
      _status = RealtimeStatus.connected;
      _statusController.add(_status);
      _retryAttempts = 0;
      
      print("✅ SDK: WebSocket Connected Successfully (Plain Text Mode)");
      
      // 7. Re-subscribe to existing channels (if any)
      _reSubscribeToAll();

      // 8. Dhageyso fariimaha soo dhacaya (The Stream)
      _channel!.stream.listen(
        (message) {
          _onMessageReceived(message);
        },
        onDone: () {
          print("🔌 SDK: Connection Closed by Server.");
          _handleDisconnect();
        },
        onError: (err) {
          print("❌ SDK: WebSocket Stream Error: $err");
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ SDK: Critical Connection Error: $e");
      _handleDisconnect();
    }
  }
  // 🆔 Identity Management
  void setUserID(String? id) {
    if (_userID == id) return;
    _userID = id;
    print("🆔 SDK: Identity set to [$id]");
    // Haddii uu qofka isbedelo, xiriirka dib u bilow si uu Server-ka cusub ugu aqoonsado
    if (_status == RealtimeStatus.connected) {
      _reconnectImmediately();
    }
  }

  // 🚀 MESSAGE DISTRIBUTOR
  void _onMessageReceived(dynamic rawMessage) {
    try {
      final data = json.decode(rawMessage);
      final String? channelName = data['channel'];
      
      if (channelName != null && _activeChannels.containsKey(channelName)) {
        _activeChannels[channelName]!.handleInternalMessage(data);
      }

      // Presence events (Optional)
      final String? eventType = data['event_type'];
      if (eventType != null && eventType.startsWith("PRESENCE_")) {
        for (var channel in _activeChannels.values) {
          channel.handleInternalMessage(data);
        }
      }
    } catch (e) {
      print("⚠️ SDK Parsing Error: $e");
    }
  }

  void _handleDisconnect() {
    if (_status == RealtimeStatus.disconnected) return;
    
    _status = RealtimeStatus.reconnecting;
    _statusController.add(_status);
    _reconnectTimer?.cancel();
    
    // Exponential Backoff (1s, 2s, 4s, 8s... ilaa 30s)
    int waitTime = (1 << _retryAttempts); 
    if (waitTime > 30) waitTime = 30;

    print("⚠️ SDK: Link lost. Retrying in $waitTime seconds...");
    _reconnectTimer = Timer(Duration(seconds: waitTime), () {
      _retryAttempts++;
      connect();
    });
  }

  void _reconnectImmediately() {
    disconnect();
    Future.delayed(Duration(milliseconds: 500), () => connect());
  }

  void _reSubscribeToAll() {
    if (_activeChannels.isNotEmpty) {
      print("📡 SDK: Re-subscribing to ${_activeChannels.length} channels...");
      for (var channel in _activeChannels.values) {
        channel.subscribe();
      }
    }
  }

  void sendCommand(Map<String, dynamic> data) {
    if (_status == RealtimeStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(data));
      } catch (e) {
        print("❌ SDK: Failed to send command -> $e");
      }
    } else {
      print("⚠️ SDK: Cannot send. Not connected.");
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _status = RealtimeStatus.disconnected;
    _statusController.add(_status);
    print("🔌 SDK: Disconnected Manually.");
  }

  SuperAIBRealtimeChannel channel(String name) {
    if (_activeChannels.containsKey(name)) return _activeChannels[name]!;
    final newChannel = SuperAIBRealtimeChannel(name, this);
    _activeChannels[name] = newChannel;
    return newChannel;
  }

  bool get isConnected => _status == RealtimeStatus.connected;
}