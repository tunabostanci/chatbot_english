import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'chat_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ChatCubit extends Cubit<ChatState> {
  final ChatService _service;
  StreamSubscription<List<Conversation>>? _convoSub;
  StreamSubscription<List<ChatMessage>>? _messageSub;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatCubit(this._service) : super(ChatInitial());

  /// Drawer'da gösterilecek sohbet özetlerini yükler
  void loadConversations(String userId) {
    emit(ChatStateLoading());
    _convoSub?.cancel();

    _service.fetchConversations(userId).then((conversations) {
      if (conversations.isEmpty) {
        print("No conversations found. Creating a new conversation.");
        _service
            .createNewConversation(userId, "New Conversation")
            .then((conversationId) {
          print("New conversation created with ID: $conversationId");
          loadConversations(userId); // Reload conversations after creation
        });
      } else {
        emit(ChatConversationsLoaded(conversations));
      }
    }).catchError((e) {
      emit(ChatStateError(e.toString()));
    });

    _convoSub = _service.conversationStream(userId).listen(
      (convos) {
        emit(ChatConversationsLoaded(convos));
      },
      onError: (e) => emit(ChatStateError(e.toString())),
    );
  }

  /// Yeni bir sohbet oluşturur ve listeyi günceller
  Future<void> createConversation(String userId, String title) async {
    emit(ChatStateLoading());
    try {
      await _service.createNewConversation(userId, title);
      loadConversations(userId);
    } catch (e) {
      emit(ChatStateError(e.toString()));
    }
  }

  /// Seçilen sohbetin mesaj akışını dinler
  void loadMessages(String userId, String conversationId) {
    _messageSub?.cancel(); // Eski stream iptal
    emit(ChatStateLoading()); // Yükleme durumu

    _messageSub = _service.messageStream(userId, conversationId).listen(
          (msgs) {
        if (msgs.isNotEmpty) {
          emit(ChatMessagesLoaded(conversationId, msgs));
          print('Mesajlar yuklendi: ${msgs.length} adet.');// Mesajlar yüklendi
        } else {
          emit(ChatMessagesLoaded(conversationId, [])); // Boş mesajlar
          print('Mesaj yok');
        }
      },
      onError: (e) => emit(ChatStateError(e.toString())), // Hata durumu
    );
    print('Load messages state i : $state');
  }


  /// Kullanıcı ve bot mesajlarını kaydeder
  Future<void> sendMessage(String userId, String conversationId, String text) async {
    try {
      // Kullanıcı mesajını kaydet
      final messageRef = await _firestore.collection('messages').add({
        'sender': 'user',
        'text': text,
        'timestamp': DateTime.now(),
      });

      final userMessage = ChatMessage(
        id: messageRef.id,
        sender: 'user',
        text: text,
        timestamp: DateTime.now(),
      );
      await _service.saveMessage(userId, conversationId, userMessage);
      print('Kullanıcı mesajı gönderiliyor: $text');

      // AI bot cevabını al
      final botText = await _service.getBotResponse(text);
      print('AI yanıtı alındı: $botText');

      // Bot mesajını kaydet
      final botMessage = ChatMessage(
        id: '',  // Burada bot mesajını kaydederken id kullanmaya gerek yok, Firestore otomatik verir.
        sender: 'bot',
        text: botText,
        timestamp: DateTime.now(),
      );
      await _service.saveMessage(userId, conversationId, botMessage);

      loadMessages(userId, conversationId);
    } catch (e) {
      // Hata durumunda hata mesajı verir
      emit(ChatStateError('Mesaj gönderilirken bir hata oluştu: $e'));
    }
  }


  @override
  Future<void> close() async {
    await _convoSub?.cancel();
    await _messageSub?.cancel();
    return super.close();
  }
}
