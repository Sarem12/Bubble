import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<List<EnrichedConversation>> getConversations();
  Future<List<Message>> getMessages(String conversationId);
  Future<bool> getPresence(String userId);
  Future<bool> deleteMessage(String messageId, String conversationId);
  Future<bool> toggleReaction(String messageId, String emoji);
  Future<Map<String, dynamic>> createConversation(String targetUserId);
  Future<bool> deleteConversation(String conversationId);
}
