import 'package:dio/dio.dart';
import 'realtime_channel.dart';

class SuperAIBRealtime {
  final Dio _dio;
  final String projectRef;
  final String _apiKey;

  // Kaydka qolalka si aanan mar kasta HTTP u wicin
  final Map<String, SuperAIBRealtimeChannel> _activeChannels = {};

  SuperAIBRealtime(this._dio, this.projectRef, this._apiKey);

  // 🚀 GET CHANNEL (The HTTP Way)
  // Kani waa async waayo waa inuu pgAdmin ka soo hubiyo ID-ga qolka
  Future<SuperAIBRealtimeChannel?> channel(String name) async {
    // Haddii uu qolku hore u furnaa, soo celi isaga
    if (_activeChannels.containsKey(name)) return _activeChannels[name];

    try {
      print("📡 SDK: Registering channel [$name] via HTTP...");
      
      // 1. Marka hore pgAdmin ka hubi ama ka abuuro qolka (POST)
      final response = await _dio.post(
        'projects/$projectRef/realtime/channels',
        data: {'name': name},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Hel UUID-ga saxda ah ee pgAdmin u dhalisay qolka
        final String channelId = response.data['data']['id'];
        
        // 2. Abuuro Class-ka qolka
        final newChannel = SuperAIBRealtimeChannel(name, channelId, this, _dio);
        
        _activeChannels[name] = newChannel;
        print("✅ SDK: Channel [$name] is ready (ID: $channelId)");
        return newChannel;
      }
    } catch (e) {
      print("❌ SDK Error: Could not initialize channel via HTTP: $e");
    }
    return null;
  }

  // Fallback methods si uusan SDK-gaagu ugu crash-gareyn meelaha WS looga baahnaa
  void connect() => print("ℹ️ SDK: Using HTTP Realtime mode (No WS needed).");
  void disconnect() => _activeChannels.forEach((k, v) => v.unsubscribe());
  bool get isConnected => true; 
  Stream<bool> get onStatusChange => Stream.value(true);
}