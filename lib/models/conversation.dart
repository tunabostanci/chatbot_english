import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String title;
  final Timestamp lastUpdated;

  Conversation({required this.id, required this.title, required this.lastUpdated});

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      title: data['title'],
      lastUpdated: data['lastUpdated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'lastUpdated': lastUpdated,
    };
  }
}
