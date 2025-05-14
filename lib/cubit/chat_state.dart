import '../models/conversation.dart';
import '../models/chat_message.dart';

/// ChatState - Tüm olası sohbet durumlarını tanımlar
abstract class ChatState {}

/// Başlangıç durumu (ilk açılışta vs.)
class ChatInitial extends ChatState {}

/// Yükleme durumu (API veya Firestore verisi bekleniyor)
class ChatStateLoading extends ChatState {}

/// Hata durumu
class ChatStateError extends ChatState {
  final String message;
  ChatStateError(this.message);

  @override
  String toString() => 'ChatStateError: $message';
}

/// Sohbet özetleri başarıyla yüklendi
class ChatConversationsLoaded extends ChatState {
  final List<Conversation> conversations;
  ChatConversationsLoaded(this.conversations);
}

/// Seçilen sohbetin mesajları başarıyla yüklendi
class ChatMessagesLoaded extends ChatState {
  final String conversationId;
  final List<ChatMessage> messages;
  ChatMessagesLoaded(this.conversationId, this.messages);
}
