import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OpenAI _openAI;

  ChatService() : _openAI = OpenAI.instance.build(
    token: dotenv.env['OPENAI_API_KEY']!,
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
  );

  /// Yardımcı referanslar
  CollectionReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('conversations');

  CollectionReference<Map<String, dynamic>> _messagesRef(
      String userId, String conversationId) =>
      _userRef(userId).doc(conversationId).collection('messages');

  /// Sohbet listesini dinler
  Stream<List<Conversation>> conversationStream(String userId) {
    return _userRef(userId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((qs) {
      print("Veriler geldi: ${qs.docs.length} konuşma bulundu.");
      return qs.docs.map(Conversation.fromFirestore).toList();
    });
  }

  /// Sohbet listesini bir kere çeker
  Future<List<Conversation>> fetchConversations(String userId) async {
    final snapshot = await _userRef(userId)
        .orderBy('lastUpdated', descending: true)
        .get();
    return snapshot.docs.map(Conversation.fromFirestore).toList();
  }

  /// Yeni sohbet oluşturur
  Future<String> createNewConversation(String userId, String title) async {
    final docRef = _userRef(userId).doc();
    await docRef.set({
      'title': title,
      'lastUpdated': Timestamp.now(),
    });
    return docRef.id;
  }

  /// Mevcut ya da yeni sohbet ID'sini döner
  Future<String> getOrCreateConversation(String userId, String title) async {
    final conversations = await fetchConversations(userId);
    return conversations.isEmpty
        ? await createNewConversation(userId, title)
        : conversations.first.id;
  }

  /// Belirli sohbetin mesajlarını dinler
  Stream<List<ChatMessage>> messageStream(
      String userId, String conversationId) {
    return _messagesRef(userId, conversationId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map(ChatMessage.fromDoc).toList());
  }

  /// Mesaj kaydeder ve zaman damgasını günceller
  Future<void> saveMessage(
      String userId, String conversationId, ChatMessage msg) async {
    try {
      final ref = _messagesRef(userId, conversationId);
      await ref.add(msg.toJson());

      await _userRef(userId).doc(conversationId)
          .update({'lastUpdated': Timestamp.now()});

      print('Mesaj kaydedildi: ${msg.text}');
    } catch (e) {
      print('Mesaj kaydedilirken hata: $e');
    }
  }

  /// AI yanıtı alır
  Future<String> getBotResponse(String userMessage) async {
    try {
      print("AI'ya gönderilen: $userMessage");
      final req = ChatCompleteText(
        messages: [
          {
            'role': 'system',
            'content':
            'You are an AI English tutor. Introduce yourself in your first message. '
                'Do not discuss topics unrelated to English language learning. Focus on vocabulary and verbs.'
          },
          {'role': 'user', 'content': userMessage},
        ],
        maxToken: 200,
        model: Gpt4oMiniChatModel(),
      );
      final res = await _openAI.onChatCompletion(request: req);
      final reply = res?.choices.first.message?.content.trim();
      print("AI yanıtı: $reply");
      return reply ?? 'AI yanıt veremedi.';
    } catch (e, stack) {
      print('AI yanıtı alınırken hata: $e');
      print('Stack trace: $stack');
      return 'AI yanıt veremedi.';
    }
  }

  /// ChatCubit destek metodları
  Stream<List<Conversation>> getConversations(String userId) =>
      conversationStream(userId);

  Stream<List<ChatMessage>> getMessages(
      String userId, String conversationId) =>
      messageStream(userId, conversationId);

  Future<void> sendMessage(
      String userId, String conversationId, ChatMessage msg) =>
      saveMessage(userId, conversationId, msg);

  Future<void> sendMessageWithConversationCheck(
      String userId, String title, ChatMessage msg) async {
    final conversationId = await getOrCreateConversation(userId, title);
    await saveMessage(userId, conversationId, msg);
  }
}
