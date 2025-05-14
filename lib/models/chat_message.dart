import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  // Firestore'dan veriyi almak için fromDoc metodu
  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Veriyi çekerken timestamp'in doğru formatta olup olmadığını kontrol et
    final timestamp = data['timestamp'] != null && data['timestamp'] is Timestamp
        ? (data['timestamp'] as Timestamp).toDate() // Timestamp verisini DateTime'a dönüştür
        : DateTime.now(); // Eğer timestamp verisi yoksa, şu anki zamanı kullan

    return ChatMessage(
      id: doc.id,
      sender: data['sender'] ?? '', // sender null ise boş string döndür
      text: data['text'] ?? '',     // text null ise boş string döndür
      timestamp: timestamp,
    );
  }

  // Veriyi JSON formatında saklamak için toJson metodu
  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp), // timestamp'i Firestore Timestamp formatına dönüştür
    };
  }
}
