import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import '../../../../core/network/api_client.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';


class ChatRemoteDataSource {
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      final uri = Uri.tryParse(customUrl);
      if (uri != null && uri.host.isNotEmpty) {
        return 'http://${uri.host}:4000/api';
      }
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:4000/api';
    return 'http://127.0.0.1:4000/api';
  }

  final Dio _chatDio = Dio(
    BaseOptions(
      baseUrl: baseUrl, 
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.addAll(ApiClient.dio.interceptors);

  Future<List<EnrichedConversation>> getConversations() async {
    final response = await ApiClient.dio.get('/conversations');
    if (response.data is List) {
      List<EnrichedConversation> convs = (response.data as List).map((json) => EnrichedConversation.fromJson(json)).toList();
      
      if (convs.isNotEmpty) {
        try {
          final ids = convs.map((e) => e.id).join(',');
          final lastMsgRes = await _chatDio.get('/conversations/last-messages', queryParameters: {'ids': ids});
          final map = lastMsgRes.data as Map<String, dynamic>? ?? {};

          convs = convs.map((c) {
            if (map.containsKey(c.id) && map[c.id] != null) {
              final lastInfo = map[c.id] as Map<String, dynamic>;
              return c.copyWith(lastMessage: (lastInfo['content'] ?? '').toString());
            }
            return c;
          }).toList();
        } catch (_) {}
      }
      return convs;
    }
    return [];
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _chatDio.get('/conversations/$conversationId/messages', queryParameters: {
      'limit': 50,
    });
    if (response.data is List) {
      return (response.data as List).map((json) => Message.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> getPresence(String userId) async {
    try {
      final response = await _chatDio.get('/presence/$userId');
      return response.data['online'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId, String conversationId) async {
    try {
      await _chatDio.delete('/messages/$messageId', queryParameters: {'conversation_id': conversationId});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleReaction(String messageId, String emoji) async {
    try {
      await _chatDio.post('/messages/$messageId/reactions', data: {'emoji': emoji});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createConversation(String targetUserId) async {
    final response = await ApiClient.dio.post('/conversations', data: {
      'target_user_id': targetUserId,
    });
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      await _chatDio.delete('/conversations/$conversationId');
      return true;
    } catch (_) {
      return false;
    }
  }
}

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource();
});

