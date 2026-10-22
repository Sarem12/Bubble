import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/secure_storage.dart';
import 'api_client.dart';

enum ConnectionStateStatus {
  connected,
  connecting,
  noNetwork,
  disconnected,
}

class WebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();
  bool _isIntentionalDisconnect = false;
  Timer? _reconnectTimer;
  
  ConnectionStateStatus _status = ConnectionStateStatus.disconnected;
  ConnectionStateStatus get status => _status;

  final StreamController<ConnectionStateStatus> _statusController =
      StreamController<ConnectionStateStatus>.broadcast();
  Stream<ConnectionStateStatus> get statusStream => _statusController.stream;

  final List<Map<String, dynamic>> _offlineQueue = [];
  
  static String get _host {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      final uri = Uri.tryParse(customUrl);
      if (uri != null && uri.host.isNotEmpty) return uri.host;
    }
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }

  String get _baseUrl {
    return 'ws://$_host:4000/ws';
  }

  Stream<dynamic> get stream => _controller.stream;
  bool get isConnected => _status == ConnectionStateStatus.connected && _channel != null;

  void _updateStatus(ConnectionStateStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final s = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 1));
      s.destroy();
      return true;
    } catch (_) {
      try {
        final s = await Socket.connect(_host, 4000, timeout: const Duration(milliseconds: 800));
        s.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> connect() async {
    if (isConnected) return;
    _isIntentionalDisconnect = false;
    _reconnectTimer?.cancel();
    
    final token = await ApiClient.getValidAccessToken();
    final deviceId = await SecureStorage.getDeviceId(); 
    
    if (token == null) {
      _updateStatus(ConnectionStateStatus.disconnected);
      return; 
    }

    final hasNet = await _hasInternet();
    if (!hasNet) {
      _updateStatus(ConnectionStateStatus.noNetwork);
      _scheduleReconnect();
      return;
    }

    _updateStatus(ConnectionStateStatus.connecting);

    _cleanupSocket();

    final uri = Uri.parse('$_baseUrl?token=$token&device_id=$deviceId');
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      
      // Wait for socket handshake
      await channel.ready.timeout(const Duration(seconds: 5));

      _updateStatus(ConnectionStateStatus.connected);

      _channelSubscription = channel.stream.listen(
        (data) {
          if (data is String && data.contains('\n')) {
            for (final line in data.split('\n')) {
              final trimmed = line.trim();
              if (trimmed.isNotEmpty) {
                _controller.add(trimmed);
              }
            }
          } else {
            _controller.add(data);
          }
        },
        onError: (e) {
          _cleanupSocket();
          _handleDisconnect();
        },
        onDone: () {
          _cleanupSocket();
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _flushOfflineQueue();
    } catch (e) {
      _cleanupSocket();
      _handleDisconnect();
    }
  }

  void _cleanupSocket() {
    try {
      _channelSubscription?.cancel();
    } catch (_) {}
    _channelSubscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  Future<void> _handleDisconnect() async {
    if (_isIntentionalDisconnect) {
      _updateStatus(ConnectionStateStatus.disconnected);
      return;
    }

    _cleanupSocket();

    final hasNet = await _hasInternet();
    if (!hasNet) {
      _updateStatus(ConnectionStateStatus.noNetwork);
    } else {
      _updateStatus(ConnectionStateStatus.connecting);
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_status == ConnectionStateStatus.connected) {
        timer.cancel();
        return;
      }
      
      final hasNet = await _hasInternet();
      if (!hasNet) {
        _updateStatus(ConnectionStateStatus.noNetwork);
        return;
      }

      _updateStatus(ConnectionStateStatus.connecting);
      timer.cancel();
      connect();
    });
  }

  void _flushOfflineQueue() {
    if (_channel == null || _status != ConnectionStateStatus.connected || _offlineQueue.isEmpty) return;
    for (final payload in List.from(_offlineQueue)) {
      try {
        _channel!.sink.add(jsonEncode(payload));
        _offlineQueue.remove(payload);
      } catch (_) {
        break;
      }
    }
  }

  bool sendMessage(String conversationId, String recipientId, String content, {String? clientId}) {
    final payload = {
      "action": "send_message",
      "conversation_id": conversationId,
      "recipient_id": recipientId,
      "content": content,
      if (clientId != null && clientId.isNotEmpty) "client_id": clientId,
    };
    
    if (_status != ConnectionStateStatus.connected || _channel == null) {
      _offlineQueue.add(payload);
      if (_status == ConnectionStateStatus.disconnected) {
        connect();
      } else if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
        _scheduleReconnect();
      }
      return false; // Queued
    }
    
    try {
      _channel!.sink.add(jsonEncode(payload));
      return true;
    } catch (_) {
      _offlineQueue.add(payload);
      _handleDisconnect();
      return false;
    }
  }
  
  bool markAsRead(String conversationId, String recipientId) {
    final payload = {
      "action": "mark_read",
      "conversation_id": conversationId,
      "recipient_id": recipientId,
    };
    if (_status == ConnectionStateStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(payload));
        return true;
      } catch (_) {}
    } else {
      // Keep in offline queue if not connected yet
      if (!_offlineQueue.any((item) => item['action'] == 'mark_read' && item['conversation_id'] == conversationId)) {
        _offlineQueue.add(payload);
      }
    }
    return false;
  }

  bool sendTyping(String conversationId, String recipientId) {
    if (_status != ConnectionStateStatus.connected || _channel == null) return false;
    final payload = {
      "action": "typing",
      "conversation_id": conversationId,
      "recipient_id": recipientId,
    };
    try {
      _channel!.sink.add(jsonEncode(payload));
      return true;
    } catch (_) {
      return false;
    }
  }

  bool deleteMessage(String conversationId, String recipientId, String messageId) {
    final payload = {
      "action": "delete_message",
      "conversation_id": conversationId,
      "recipient_id": recipientId,
      "message_id": messageId,
    };
    if (_status == ConnectionStateStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(payload));
        return true;
      } catch (_) {}
    }
    return false;
  }

  bool reactMessage(String conversationId, String recipientId, String messageId, rawEmoji) {
    final payload = {
      "action": "react_message",
      "conversation_id": conversationId,
      "recipient_id": recipientId,
      "message_id": messageId,
      "emoji": rawEmoji,
    };
    if (_status == ConnectionStateStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(payload));
        return true;
      } catch (_) {}
    }
    return false;
  }

  bool deleteConversation(String conversationId, String recipientId) {
    final payload = {
      "action": "delete_conversation",
      "conversation_id": conversationId,
      "recipient_id": recipientId,
    };
    if (_status == ConnectionStateStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(payload));
        return true;
      } catch (_) {}
    }
    return false;
  }

  void disconnect() {
    _isIntentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _cleanupSocket();
    _updateStatus(ConnectionStateStatus.disconnected);
  }
}
