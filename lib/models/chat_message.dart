// chat_message.dart
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
    return ChatMessage(
      id: doc.id,
      sender: doc['sender'],
      text: doc['text'],
      timestamp: (doc['timestamp'] as Timestamp).toDate(),
    );
  }

  // Veriyi JSON formatında saklamak için toJson metodu
  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
