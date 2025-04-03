import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/chat_cubit.dart';

class ChatScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI ChatBot")),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, List<Map<String, String>>>(
              builder: (context, messages) {
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message["sender"] == "user";
                    final isTyping = message["message"] == "Typing...";

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isTyping
                            ? _typingIndicator() // AI yazıyorsa animasyon göster
                            : Text(
                          message["message"]!,
                          style: TextStyle(color: isUser ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    context.read<ChatCubit>().sendMessage(_controller.text);
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // "Typing..." için animasyonlu widget
  Widget _typingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(),
        SizedBox(width: 4),
        _dot(delay: 300),
        SizedBox(width: 4),
        _dot(delay: 600),
      ],
    );
  }

  Widget _dot({int delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      tween: Tween(begin: 0.3, end: 1),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      onEnd: () => Future.delayed(Duration(milliseconds: delay)),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      ),
    );
  }
}
