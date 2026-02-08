import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'realtime_channel.dart';

enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

class SuperAIBRealtime {
  final String _baseUrl;
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

  // 🆔 aqoonsiga User-ka
  void setUserID(String? id) {
    if (_userID == id) return;
    _userID = id;
    print("🆔 SDK: Identity set to [$id]");
    if (_status == RealtimeStatus.connected) {
      _reconnectImmediately();
    }
  }

  // 🚀 CONNECTION ENGINE (STABLE VERSION)
 Future<void> connect() async {
    if (_status == RealtimeStatus.connected || _status == RealtimeStatus.connecting) return;

    _status = RealtimeStatus.connecting;
    _statusController.add(_status);

    try {
      String cleanBase = _baseUrl.endsWith('/') 
          ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
      
      String wsProtocol = cleanBase.startsWith('https') ? 'wss' : 'ws';
      String finalWsUrl = cleanBase.replaceFirst(RegExp(r'^http(s)?'), wsProtocol);
      
      final String wsUrl = "$finalWsUrl/ws/$_projectRef?api_key=$_apiKey" + 
                           (_userID != null ? "&user_id=$_userID" : "");

      print("🌐 SDK: Connecting to $wsUrl");

      // 🚀 NUCLEAR FIX: Isticmaal WebSocket toos ah ka hor intaanan wrap gareyn
      // Kani wuxuu noo oggolaanayaa inaan damino compression-ka iOS.
      final socket = await WebSocket.connect(wsUrl);
      socket.pingInterval = const Duration(seconds: 10);
      
      _channel = IOWebSocketChannel(socket);

      _status = RealtimeStatus.connected;
      _statusController.add(_status);
      _retryAttempts = 0;
      
      print("✅ SDK: WebSocket Connected!");

      // 🚀 MUHIIM: Sug 500ms ka hor intaanan fariin dirin si socket-ku u dego
      Future.delayed(const Duration(milliseconds: 500), () {
        _reSubscribeToAll();
      });

      _channel!.stream.listen(
        (message) => _onMessageReceived(message),
        onDone: () => _handleDisconnect(),
        onError: (err) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ SDK Connect Error: $e");
      _handleDisconnect();
    }
  }

  void sendCommand(Map<String, dynamic> data) {
    if (_status == RealtimeStatus.connected && _channel != null) {
      final String rawJson = json.encode(data);
      print("📤 SDK SENDING: $rawJson");
      _channel!.sink.add(rawJson);
    }
  }
  // 📥 MESSAGE DISTRIBUTOR
  void _onMessageReceived(dynamic rawMessage) {
    try {
      final data = json.decode(rawMessage);
      final String? channelName = data['channel'];
      
      if (channelName != null && _activeChannels.containsKey(channelName)) {
        _activeChannels[channelName]!.handleInternalMessage(data);
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
    
    int waitTime = (1 << _retryAttempts); 
    if (waitTime > 30) waitTime = 30;

    print("🔌 SDK: Connection lost. Retrying in $waitTime seconds...");
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