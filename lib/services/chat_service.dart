import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';

class ChatService {
  OpenAI? _openAI;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OpenAI get _ai {
    if (_openAI == null) {
      final apiKey = dotenv.env['OPENAI_API_KEY']!;
      _openAI = OpenAI.instance.build(
        token: apiKey,
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
      );
    }
    return _openAI!;
  }

  /// Stream: tüm sohbet özetlerini gerçek zamanlı getirir
  Stream<List<Conversation>> conversationStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((qs) {
      // Verilerin geldiğini kontrol et
      print("Veriler geldi: ${qs.docs.length} konuşma bulundu.");
      return qs.docs.map((d) => Conversation.fromFirestore(d)).toList();
    });
  }

  /// Future: sohbet özetlerini bir kez getirir
  Future<List<Conversation>> fetchConversations(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .orderBy('lastUpdated', descending: true)
        .get();
    return snapshot.docs.map((d) => Conversation.fromFirestore(d)).toList();
  }

  /// Yeni sohbet oluşturur
  Future<String> createNewConversation(String userId, String title) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc();
    await docRef.set({
      'title': title,
      'lastUpdated': Timestamp.now(),
    });
    return docRef.id;
  }

  /// Sohbet başlatılmamışsa yeni bir sohbet başlatır
  Future<String> getOrCreateConversation(String userId, String title) async {
    // Kullanıcı için sohbetlerin olup olmadığını kontrol et
    final conversations = await fetchConversations(userId);

    if (conversations.isEmpty) {
      // Sohbet yoksa, yeni bir sohbet oluştur
      return await createNewConversation(userId, title);
    } else {
      // Eğer sohbet varsa, ilk sohbetin ID'sini döndür
      return conversations.first.id;
    }
  }

  /// Stream: belirli bir sohbete ait mesaj akışını getirir
  Stream<List<ChatMessage>> messageStream(String userId, String conversationId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => ChatMessage.fromDoc(doc)).toList());
  }




  /// Mesaj kaydeder ve lastUpdated günceller
  Future<void> saveMessage(String userId, String conversationId, ChatMessage msg) async {
    try {
      final messagesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');

      // Mesajı ekliyoruz
      await messagesRef.add(msg.toJson());

      // Mesaj eklendikten sonra lastUpdated zamanını güncelliyoruz
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .doc(conversationId)
          .update({'lastUpdated': Timestamp.now()});

      // Başarı mesajı log'u
      print('Mesaj başarıyla kaydedildi: ${msg.text}');
    } catch (e) {
      // Hata durumunda loglama
      print('Mesaj kaydedilirken bir hata oluştu: $e');
    }
  }


  /// AI bot cevabı alır
  Future<String> getBotResponse(String userMessage) async {
    try {
      print("AI'ya gönderilen mesaj: $userMessage");
      final req = ChatCompleteText(
        messages: [
          {'role': 'system', 'content': 'You are an AI English tutor, '
              'send the first message to user and explain yourself such as '
              'I am a Chatbot for teaching english'
              ' also dont talk about topics unrelated to english '
              'and english learning , try to talk about verbs and vocabulary'},
          {'role': 'user', 'content': userMessage},
        ],
        maxToken: 200,
        model: Gpt4oMiniChatModel(),
      );
      final res = await _ai.onChatCompletion(request: req);
      print("AI cevabı: ${res?.choices.first.message?.content}");
      return res?.choices.first.message?.content.trim() ?? 'AI yanıt veremedi.';
    } catch (_) {
      return 'AI yanıt veremedi.';
    }
  }

  // Aliasing for ChatCubit compatibility

  /// ChatCubit loadConversations -> kullanabilir
  Stream<List<Conversation>> getConversations(String userId) =>
      conversationStream(userId);

  /// ChatCubit loadMessages -> kullanabilir
  Stream<List<ChatMessage>> getMessages(
      String userId, String conversationId) =>
      messageStream(userId, conversationId);

  /// ChatCubit sendMessage -> kullanabilir
  Future<void> sendMessage(
      String userId, String conversationId, ChatMessage msg) =>
      saveMessage(userId, conversationId, msg);

  /// Mesaj göndermeden önce sohbeti kontrol eder ve yeni sohbet başlatır
  Future<void> sendMessageWithConversationCheck(
      String userId, String title, ChatMessage msg) async {
    // Sohbeti kontrol et ve oluştur
    String conversationId = await getOrCreateConversation(userId, title);

    // Mesajı kaydet
    await saveMessage(userId, conversationId, msg);
  }
}
