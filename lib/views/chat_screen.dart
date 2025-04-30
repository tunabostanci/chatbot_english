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

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    // Geçmiş sohbetleri yükle
    context.read<ChatCubit>().loadConversations(_uid);
  }

  void _send(String conversationId, String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatCubit>().sendMessage(_uid, conversationId, text);
    _textController.clear();
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 60,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
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
                backgroundImage: NetworkImage(
                  FirebaseAuth.instance.currentUser?.photoURL ?? '',
                ),
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
                          title: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            // Başlık altına lastUpdated ekleyin
                            DateFormat('dd/MM – HH:mm').format(convo.lastUpdated as DateTime),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context.read<ChatCubit>().loadMessages(_uid, convo.id);
                          },
                        );
                      },
                    );
                  }
                  // Hata veya başka durumda mesaj göster
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

                  if (messages.isEmpty) {
                    return const Center(child: Text('Henüz mesaj yok'));
                  }
                  // Scroll to bottom on new message
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(_scroll.position.maxScrollExtent);
                    }
                  });
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
                      final state = context.read<ChatCubit>().state;
                      if (state is ChatMessagesLoaded) {
                        _send(state.conversationId, text);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      print('Send button pressed.');
                      final state = context.read<ChatCubit>().state;
                      print('Current state: $state');

                      if (state is ChatConversationsLoaded) {
                        print('Conversations list: ${state.conversations}');

                        // conversations listesinden bir tane seçelim
                        final conversation = state.conversations.isNotEmpty ? state.conversations[0] : null;
                        if (conversation != null) {
                          String conversationId = conversation.id; // Burada conversationId'yi alıyoruz
                          _send(conversationId, _textController.text);
                        } else {
                          print('No conversation found!');
                        }
                      } else if (state is ChatMessagesLoaded) {
                        _send(state.conversationId, _textController.text);
                      } else {
                        print('State is neither ChatMessagesLoaded nor ChatConversationsLoaded');
                      }
                    }



                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
