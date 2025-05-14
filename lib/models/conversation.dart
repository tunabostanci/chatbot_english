import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String title;
  final Timestamp lastUpdated;

  Conversation({
    required this.id,
    required this.title,
    required this.lastUpdated,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Eğer 'lastUpdated' verisi null ise, şu anki zamanı al
    final lastUpdated = data['lastUpdated'] ?? Timestamp.now();

    return Conversation(
      id: doc.id,
      title: data['title'] ?? '', // Eğer title null ise boş string gönder
      lastUpdated: lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'lastUpdated': lastUpdated,
    };
  }
}
