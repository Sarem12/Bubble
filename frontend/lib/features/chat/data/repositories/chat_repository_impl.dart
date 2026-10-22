import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<EnrichedConversation>> getConversations() {
    return _remoteDataSource.getConversations();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) {
    return _remoteDataSource.getMessages(conversationId);
  }

  @override
  Future<bool> getPresence(String userId) {
    return _remoteDataSource.getPresence(userId);
  }

  @override
  Future<bool> deleteMessage(String messageId, String conversationId) {
    return _remoteDataSource.deleteMessage(messageId, conversationId);
  }

  @override
  Future<bool> toggleReaction(String messageId, String emoji) {
    return _remoteDataSource.toggleReaction(messageId, emoji);
  }

  @override
  Future<Map<String, dynamic>> createConversation(String targetUserId) {
    return _remoteDataSource.createConversation(targetUserId);
  }

  @override
  Future<bool> deleteConversation(String conversationId) {
    return _remoteDataSource.deleteConversation(conversationId);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final ds = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(ds);
});
