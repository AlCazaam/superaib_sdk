import 'dart:async';
import 'dart:convert';
import 'dart:io'; // MUHIIM: Waxaan u baahanahay HttpClient-ka hoose
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

  // 🚀 CONNECTION ENGINE (ROCK SOLID VERSION)
  Future<void> connect() async {
    if (_status == RealtimeStatus.connected || _status == RealtimeStatus.connecting) {
      print("ℹ️ SDK: Already connected or connecting. Skipping...");
      return;
    }

    _status = RealtimeStatus.connecting;
    _statusController.add(_status);

    // 1. URL Building & Cleaning
    final String cleanBase = _baseUrl.endsWith('/') 
        ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    
    final String wsProtocol = cleanBase.startsWith('https') ? 'wss' : 'ws';
    final String finalBaseUrl = cleanBase.replaceFirst(RegExp(r'^http(s)?'), wsProtocol);
    
    final String wsUrl = "$finalBaseUrl/ws/$_projectRef?api_key=$_apiKey" + 
                         (_userID != null ? "&user_id=$_userID" : "");

    print("🌐 SDK: Starting Connection to [$wsUrl]");

    try {
      // 2. 🚀 THE NUCLEAR FIX FOR RSV BITS (OPCODE 7)
      // Waxaan isticmaalaynaa WebSocket-ka hoose ee Dart si aan compression-ka gabi ahaanba u damino
      final WebSocket socket = await WebSocket.connect(
        wsUrl,
        compression: CompressionOptions.compressionOff,
      ).timeout(const Duration(seconds: 10));

      // 3. Ku dhex xir IOWebSocketChannel
      _channel = IOWebSocketChannel(socket);

      // 4. Update Status
      _status = RealtimeStatus.connected;
      _statusController.add(_status);
      _retryAttempts = 0;
      
      print("✅ SDK: WebSocket Connected Successfully!");

      // 5. Dib u subscribe-garee qolalkii hore
      _reSubscribeToAll();

      // 6. Listen to Stream
      _channel!.stream.listen(
        (message) {
          print("📩 SDK: Raw Message Received -> $message");
          _onMessageReceived(message);
        },
        onDone: () {
          print("🔌 SDK: Connection Closed by Server.");
          _handleDisconnect();
        },
        onError: (err) {
          print("❌ SDK: Stream Error occurred -> $err");
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ SDK: Connection Failed to Start -> $e");
      _handleDisconnect();
    }
  }

  // Identity Management
  void setUserID(String? id) {
    if (_userID == id) return;
    _userID = id;
    print("🆔 SDK: Identity set to [$id]");
    if (_status == RealtimeStatus.connected) _reconnectImmediately();
  }

  // 🚀 4. MESSAGE DISTRIBUTOR
  void _onMessageReceived(dynamic rawMessage) {
    try {
      final data = json.decode(rawMessage);
      final String? channelName = data['channel'];
      
      if (channelName != null && _activeChannels.containsKey(channelName)) {
        _activeChannels[channelName]!.handleInternalMessage(data);
      }

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
    connect();
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