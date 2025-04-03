import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/chat_service.dart';

class ChatCubit extends Cubit<List<Map<String, String>>> {
  final ChatService _chatService;

  ChatCubit(this._chatService) : super([]);

  void sendMessage(String message) async {
    if (message.isNotEmpty) {
      emit([...state, {"sender": "user", "message": message}]);

      // Boş mesajı botun yazmaya başladığını göstermek için ekle
      emit([...state, {"sender": "bot", "message": "Typing..."}]);

      final aiResponse = await _chatService.sendMessage(message);

      // Typing... mesajını kaldır ve harf harf ekle
      _simulateTypingEffect(aiResponse);
    }
  }

  void _simulateTypingEffect(String fullMessage) async {
    List<Map<String, String>> newState = List.from(state);
    newState.removeLast(); // "Typing..." mesajını kaldır
    newState.add({"sender": "bot", "message": ""}); // Yeni boş bot mesajı ekle

    for (int i = 0; i < fullMessage.length; i++) {
      await Future.delayed(Duration(milliseconds: 50)); // 50ms gecikme
      newState.last["message"] = fullMessage.substring(0, i + 1);
      emit(List.from(newState)); // Yeni state yayınla
    }
  }
}
