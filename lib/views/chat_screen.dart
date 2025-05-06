import 'package:chatbot3/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scroll = ScrollController();
  final TextEditingController _textController = TextEditingController();
  late final String _uid;
  String? _activeConversationId; // ✅ seçilen konuşma ID'si

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    context.read<ChatCubit>().loadConversations(_uid);
  }

  void _send(String conversationId, String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatCubit>().sendMessage(_uid, conversationId, text);
    _textController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI ChatBot"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(FirebaseAuth.instance.currentUser?.displayName ?? ''),
              accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(FirebaseAuth.instance.currentUser?.photoURL ?? ''),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Geçmiş Sohbetler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  if (state is ChatStateLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatConversationsLoaded) {
                    final convos = state.conversations;
                    if (convos.isEmpty) {
                      return const Center(child: Text('Henüz sohbet yok'));
                    }
                    return ListView.separated(
                      itemCount: convos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final convo = convos[i];
                        final preview = convo.title.length > 30
                            ? '${convo.title.substring(0, 30)}…'
                            : convo.title;
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            DateFormat('dd/MM – HH:mm').format(convo.lastUpdated as DateTime),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _activeConversationId = convo.id; // ✅ ID’yi kaydet
                            context.read<ChatCubit>().loadMessages(_uid, convo.id);
                          },
                        );
                      },
                    );
                  }
                  return const Center(child: Text('Veri yüklenemedi'));
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () {
                context.read<AuthBloc>().add(const AuthEventLogout());
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is ChatStateLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChatMessagesLoaded) {
                  final messages = state.messages;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(_scroll.position.maxScrollExtent);
                    }
                  });

                  if (messages.isEmpty) {
                    return const Center(child: Text('Henüz mesaj yok'));
                  }

                  return ListView.builder(
                    controller: _scroll,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUser = message.sender == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text('Sohbet seçin veya yeni sohbet başlatın'));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: "Type a message..."),
                    onSubmitted: (text) {
                      if (_activeConversationId != null) {
                        _send(_activeConversationId!, text);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    final text = _textController.text.trim();
                    if (text.isEmpty) return;

                    if (_activeConversationId != null) {
                      _send(_activeConversationId!, text);
                    } else {
                      print('Sohbet seçilmemiş!');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

