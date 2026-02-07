import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'realtime_channel.dart';

enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

class SuperAIBRealtime {
  final String _baseUrl;
  final String _projectRef;
  final String _apiKey;
  String? _userID; // 🆔 Kani waa muhiim

  WebSocketChannel? _channel;
  RealtimeStatus _status = RealtimeStatus.disconnected;
  
  final Map<String, SuperAIBRealtimeChannel> _activeChannels = {};
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  Stream<RealtimeStatus> get onStatusChange => _statusController.stream;

  int _retryAttempts = 0;
  Timer? _reconnectTimer;

  SuperAIBRealtime(this._baseUrl, this._projectRef, this._apiKey);

  // 🚀 1. IDENTITY MANAGEMENT (Halkaan kaga bado qaladka)
  void setUserID(String? id) {
    if (_userID == id) return;
    _userID = id;
    print("🆔 SDK: Identity set to [$id]");
    
    // Haddii uu qofka isbedelo isagoo Online ah, dib u xir si uu ugu xirmo User ID-ga cusub
    if (_status == RealtimeStatus.connected) {
      _reconnectImmediately();
    }
  }

  // 🚀 2. CONNECTION ENGINE
  Future<void> connect() async {
    if (_status == RealtimeStatus.connected || _status == RealtimeStatus.connecting) return;

    _status = RealtimeStatus.connecting;
    _statusController.add(_status);

    try {
      String cleanBase = _baseUrl.endsWith('/') 
          ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
      
      String wsUrl;
      if (cleanBase.startsWith('https://')) {
        wsUrl = cleanBase.replaceFirst('https://', 'wss://');
      } else if (cleanBase.startsWith('http://')) {
        wsUrl = cleanBase.replaceFirst('http://', 'ws://');
      } else {
        wsUrl = cleanBase; 
      }

      final String finalWsUrl = "$wsUrl/ws/$_projectRef?api_key=$_apiKey" + 
                           (_userID != null ? "&user_id=$_userID" : "");

      print("🌐 SDK: Connecting to WebSocket -> $finalWsUrl");

      _channel = IOWebSocketChannel.connect(
        Uri.parse(finalWsUrl),
        pingInterval: const Duration(seconds: 10),
        headers: { 'Sec-WebSocket-Extensions': '' }, 
      );

      _status = RealtimeStatus.connected;
      _statusController.add(_status);
      _retryAttempts = 0;
      
      print("✅ SDK: WebSocket Connected Successfully!");
      _reSubscribeToAll();

      _channel!.stream.listen(
        (message) => _onMessageReceived(message),
        onDone: () => _handleDisconnect(),
        onError: (err) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  // 🚀 3. MESSAGE DISTRIBUTOR
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
    for (var channel in _activeChannels.values) {
      channel.subscribe();
    }
  }

  void sendCommand(Map<String, dynamic> data) {
    if (_status == RealtimeStatus.connected && _channel != null) {
      _channel!.sink.add(json.encode(data));
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