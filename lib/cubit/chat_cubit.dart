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
        _createNewConversationAndReload(userId);
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

  void _createNewConversationAndReload(String userId) {
    print("No conversations found. Creating a new conversation.");
    _service
        .createNewConversation(userId, "New Conversation")
        .then((conversationId) {
      print("New conversation created with ID: $conversationId");
      loadConversations(userId); // Reload conversations after creation
    });
  }

  /// Yeni bir sohbet oluşturur ve listeyi günceller
  Future<void> createConversation(String userId, String title) async {
    try {
      await _service.createNewConversation(userId, title);
      loadConversations(userId); // loadConversations metodu zaten ChatStateLoading() emit ediyor
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
      final userMessage = ChatMessage(
        id: '', // Firestore .add() zaten otomatik ID atıyor
        sender: 'user',
        text: text,
        timestamp: DateTime.now(),
      );
      await _service.saveMessage(userId, conversationId, userMessage);
      print('Kullanıcı mesajı gönderiliyor: $text');

      final botText = await _service.getBotResponse(text);
      print('AI yanıtı alındı: $botText');

      final botMessage = ChatMessage(
        id: '',
        sender: 'bot',
        text: botText,
        timestamp: DateTime.now(),
      );
      await _service.saveMessage(userId, conversationId, botMessage);

      loadMessages(userId, conversationId);
    } catch (e) {
      print('error $e');
      emit(ChatStateError('Mesaj gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }



  @override
  Future<void> close() async {
    await _convoSub?.cancel();
    await _messageSub?.cancel();
    return super.close();
  }
}
