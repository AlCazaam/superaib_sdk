import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'realtime_channel.dart';

enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

class SuperAIBRealtime {
  final Dio _dio;
  final String _projectRef;
  final String _apiKey;
  String? _userID;

  WebSocketChannel? _channel;
  RealtimeStatus _status = RealtimeStatus.disconnected;
  
  final Map<String, SuperAIBRealtimeChannel> _activeChannels = {};
  final _messageController = StreamController<dynamic>.broadcast();
  final _statusController = StreamController<RealtimeStatus>.broadcast();

  SuperAIBRealtime(this._dio, this._projectRef, this._apiKey);

  // 🚀 GETTER FOR PROJECT REF (FIXED ✅)
  String get projectRef => _projectRef;

  void setUserID(String? id) => _userID = id;

  // 🛰️ CONNECT
  Future<void> connect() async {
    if (_status == RealtimeStatus.connected || _status == RealtimeStatus.connecting) return;
    _status = RealtimeStatus.connecting;
    _statusController.add(_status);

    try {
      String cleanBase = _dio.options.baseUrl.endsWith('/') 
          ? _dio.options.baseUrl.substring(0, _dio.options.baseUrl.length - 1) : _dio.options.baseUrl;
      
      String wsUrl = cleanBase.replaceFirst(RegExp(r'^http(s)?'), cleanBase.startsWith('https') ? 'wss' : 'ws');
      final String finalUrl = "$wsUrl/ws/$_projectRef?api_key=$_apiKey" + (_userID != null ? "&user_id=$_userID" : "");

      _channel = IOWebSocketChannel.connect(Uri.parse(finalUrl), headers: {'Sec-WebSocket-Extensions': ''});
      _status = RealtimeStatus.connected;
      _statusController.add(_status);

      _channel!.stream.listen(
        (message) => _onMessageReceived(message),
        onDone: () => _handleDisconnect(),
        onError: (err) => _handleDisconnect(),
      );
    } catch (e) { _handleDisconnect(); }
  }

  // 📥 ON MESSAGE
  void _onMessageReceived(dynamic rawMessage) {
    try {
      _messageController.add(rawMessage); // U sii gudbi Notification Module
      final data = json.decode(rawMessage);
      final String? channelName = data['channel'];

      // 🚀 WAC HANDLE INTERNAL MESSAGE (FIXED ✅)
      if (channelName != null && _activeChannels.containsKey(channelName)) {
        _activeChannels[channelName]!.handleInternalMessage(data);
      }
    } catch (e) { print("⚠️ SDK Realtime Error: $e"); }
  }

  void onMessageReceived(Function(dynamic) callback) {
    _messageController.stream.listen(callback);
  }

  Future<SuperAIBRealtimeChannel?> channel(String name) async {
    if (_activeChannels.containsKey(name)) return _activeChannels[name];
    try {
      final res = await _dio.post('projects/$_projectRef/realtime/channels', data: {'name': name});
      final String cid = res.data['data']['id'];
      final newChannel = SuperAIBRealtimeChannel(name, cid, this, _dio);
      _activeChannels[name] = newChannel;
      return newChannel;
    } catch (e) { return null; }
  }

  void _handleDisconnect() {
    _status = RealtimeStatus.disconnected;
    _statusController.add(_status);
  }

  void disconnect() => _channel?.sink.close();
  bool get isConnected => _status == RealtimeStatus.connected;
  Stream<RealtimeStatus> get onStatusChange => _statusController.stream;
}