import '../models/conversation.dart';
import '../models/chat_message.dart';
import 'chat_cubit.dart';
/// ChatState abstract class
abstract class ChatState {}

/// Initial State
class ChatInitial extends ChatState {}

/// Loading State
class ChatStateLoading extends ChatState {}

/// Error State
class ChatStateError extends ChatState {
  final String message;
  ChatStateError(this.message);
}

/// Conversations Loaded State
class ChatConversationsLoaded extends ChatState {
  final List<Conversation> conversations;
  ChatConversationsLoaded(  this.conversations);
}

/// Messages Loaded State
class ChatMessagesLoaded extends ChatState {
  final String conversationId;
  final List<ChatMessage> messages;
  ChatMessagesLoaded(this.conversationId, this.messages);
}
