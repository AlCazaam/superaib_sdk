import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'realtime_channel.dart';

/// Xaaladaha xiriirka WebSocket
enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

class SuperAIBRealtime {
  final String _baseUrl;
  final String _projectRef;
  final String _apiKey;
  String? _userID; // ✅ Hadda wuu isbeddeli karaa (Dynamic Identity)

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
  /// Kani waa kan xiriirinaya User-ka markuu Login sameeyo
  void setUserID(String? id) {
    if (_userID == id) return;
    
    _userID = id;
    print("🆔 SuperAIB Realtime: Identity updated to [$id]");

    // Haddii aan horay u xirnayn, dib u bilaw xiriirka si Server-ku u barto User-ka cusub
    if (_status == RealtimeStatus.connected) {
      _reconnectImmediately();
    }
  }

  // 🚀 2. CONNECTION MANAGEMENT
  void connect() {
    if (_status == RealtimeStatus.connected || _status == RealtimeStatus.connecting) return;
    
    _status = RealtimeStatus.connecting;
    _statusController.add(_status);

    // Build WebSocket URL: Bedel http -> ws
    // Sidoo kale raaci ProjectID, API Key iyo UserID (haddii uu jiro)
    final String wsProtocol = _baseUrl.startsWith('https') ? 'wss' : 'ws';
    final String cleanUrl = _baseUrl.replaceFirst(RegExp(r'http(s)?'), wsProtocol);
    
    final wsUrl = "$cleanUrl/ws?project_id=$_projectRef&api_key=$_apiKey" + 
                  (_userID != null ? "&user_id=$_userID" : "");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      print("🌐 SuperAIB Realtime: Connecting to $wsUrl");

      _channel!.stream.listen(
        (message) => _onMessageReceived(message),
        onDone: () => _handleDisconnect(),
        onError: (err) => _handleDisconnect(),
      );

      _status = RealtimeStatus.connected;
      _statusController.add(_status);
      _retryAttempts = 0;
      
      // Markay dhuuntu dhalato, dib u subscribe gareey dhamaan qolalkii hore u furnaa
      _reSubscribeToAll();
      
    } catch (e) {
      print("❌ SuperAIB Realtime Connection Error: $e");
      _handleDisconnect();
    }
  }

  // 🚀 3. CHANNEL SYSTEM
  /// Ka dhal qol cusub ama soo qaado kii hore u jiray
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
      final String eventType = data['event_type'];

      // A. U dir fariinta qolka ay ku socoto
      if (channelName != null && _activeChannels.containsKey(channelName)) {
        _activeChannels[channelName]!.handleInternalMessage(data);
      }

      // B. Presence Handling: U qaybi dhamaan qolalka haddii uu user soo galay/baxay
      if (eventType.startsWith("PRESENCE_")) {
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
    
    // Exponential Backoff: 1s, 2s, 4s, 8s... ilaa 30s
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

  /// U dir amarada dhanka Server-ka (Internal use by Channels)
  void sendCommand(Map<String, dynamic> data) {
    if (_status == RealtimeStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(data));
      } catch (e) {
        print("❌ Failed to send command: $e");
      }
    }
  }

  // 🚀 6. DISCONNECT
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _status = RealtimeStatus.disconnected;
    _statusController.add(_status);
    print("🔌 SuperAIB Realtime: Disconnected manually.");
  }

  // Getters
  RealtimeStatus get status => _status;
  bool get isConnected => _status == RealtimeStatus.connected;
}