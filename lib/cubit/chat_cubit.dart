import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatService _service;
  StreamSubscription<List<Conversation>>? _convoSub;
  StreamSubscription<List<ChatMessage>>? _messageSub;

  ChatCubit(this._service) : super(ChatInitial());

  /// Kullanıcıya ait sohbet özetlerini yükler ve stream'e abone olur
  void loadConversations(String userId) {
    emit(ChatStateLoading());
    _convoSub?.cancel();

    _convoSub = _service.conversationStream(userId).listen(
          (convos) {
        if (convos.isEmpty) {
          // Eğer sohbet yoksa yeni bir sohbet oluşturulacak
          _createNewConversationAndReload(userId);
        } else {
          emit(ChatConversationsLoaded(convos));
        }
      },
      onError: (e) => emit(ChatStateError('Sohbetler yüklenemedi: $e')),
    );
  }

  /// Hiç sohbet yoksa yeni bir tane oluşturur ve stream'i yeniden tetikler
  void _createNewConversationAndReload(String userId) async {
    try {
      final conversationId = await _service.createNewConversation(userId, "New Conversation");
      print("Yeni sohbet oluşturuldu: $conversationId");
      // Yeni sohbet oluşturulduktan sonra, mesajları yüklemek için loadMessages tetiklenebilir
      loadMessages(userId, conversationId); // Yeni sohbetin mesajlarını yükle
    } catch (e) {
      emit(ChatStateError("Yeni sohbet oluşturulamadı: $e"));
    }
  }

  /// Yeni bir sohbet oluşturur
  Future<void> createConversation(String userId, String title) async {
    try {
      await _service.createNewConversation(userId, title);
      // Stream zaten tetiklenecek
    } catch (e) {
      emit(ChatStateError("Sohbet oluşturulamadı: $e"));
    }
  }

  /// Belirli bir sohbetin mesajlarını stream olarak dinler
  void loadMessages(String userId, String conversationId) {
    emit(ChatStateLoading());
    _messageSub?.cancel();

    _messageSub = _service.messageStream(userId, conversationId).listen(
          (messages) {
        emit(ChatMessagesLoaded(conversationId, messages));
        print("Mesajlar güncellendi: ${messages.length} adet");
      },
      onError: (e) => emit(ChatStateError("Mesajlar yüklenemedi: $e")),
    );
  }

  /// Kullanıcı mesajı gönderir ve ardından bot yanıtını kaydeder
  Future<void> sendMessage(String userId, String conversationId, String text) async {
    try {
      final timestamp = DateTime.now();

      final userMessage = ChatMessage(
        id: '',
        sender: 'user',
        text: text,
        timestamp: timestamp,
      );

      await _service.saveMessage(userId, conversationId, userMessage);
      print('Kullanıcı mesajı: "$text"');

      final botResponse = await _service.getBotResponse(text);
      print('Bot yanıtı: "$botResponse"');

      final botMessage = ChatMessage(
        id: '',
        sender: 'bot',
        text: botResponse,
        timestamp: timestamp, // Aynı timestamp ile
      );

      await _service.saveMessage(userId, conversationId, botMessage);
    } catch (e) {
      print("Mesaj gönderim hatası: $e");
      emit(ChatStateError("Mesaj gönderilirken hata oluştu: $e"));
    }
  }

  @override
  Future<void> close() async {
    await _convoSub?.cancel();
    await _messageSub?.cancel();
    return super.close();
  }
}
