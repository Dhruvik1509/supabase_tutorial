// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});
//
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final SupabaseClient client = Supabase.instance.client;
//   final TextEditingController _controller = TextEditingController();
//   List<Map<String, dynamic>> messages = [];
//   late final String userId;
//
//   @override
//   void initState() {
//     super.initState();
//     final user = client.auth.currentUser;
//     if (user != null) {
//       userId = user.id;
//       _loadMessages();
//       _subscribeToMessages();
//     }
//   }
//
//   Future<void> _loadMessages() async {
//     final response = await client
//         .from('chatmessage')
//         .select()
//         .order('created_at', ascending: true);
//     setState(() {
//       messages = List<Map<String, dynamic>>.from(response);
//     });
//   }
//
//   void _subscribeToMessages() {
//     client
//         .channel('public:chatmessage')
//         .onPostgresChanges(
//       event: PostgresChangeEvent.insert,
//       schema: 'public',
//       table: 'chatmessage',
//       callback: (payload) {
//         setState(() {
//           messages.add(payload.newRecord!);
//         });
//       },
//     )
//         .subscribe();
//   }
//
//   Future<void> _sendMessage() async {
//     final content = _controller.text.trim();
//     if (content.isEmpty) return;
//
//     await client.from('chatmessage').insert({
//       'content': content,
//       'user_id': userId,
//     });
//     _controller.clear();
//   }
//
//   Future<void> _signOut() async {
//     await client.auth.signOut();
//     Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat'),
//         actions: [
//           IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(8),
//               itemCount: messages.length,
//               itemBuilder: (_, index) {
//                 final msg = messages[index];
//                 final isMe = msg['user_id'] == userId;
//                 return Align(
//                   alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 4),
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: isMe ? Colors.blue : Colors.grey.shade800,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(msg['content'], style: const TextStyle(fontSize: 16)),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: 'Type message...',
//                       filled: true,
//                       fillColor: Colors.white10,
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final SupabaseClient client = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  final StreamController<List<Map<String, dynamic>>> _messageStreamController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  List<Map<String, dynamic>> _messages = [];
  late final String userId;

  @override
  void initState() {
    super.initState();
    final user = client.auth.currentUser;
    if (user != null) {
      userId = user.id;
      _loadMessages();
      _subscribeToMessages();
    } else {
      // TODO: Redirect to login if not authenticated
    }
  }

  Future<void> _loadMessages() async {
    final response = await client
        .from('chatmessage')
        .select()
        .order('created_at', ascending: true);

    _messages = List<Map<String, dynamic>>.from(response);
    _messageStreamController.add(_messages);
  }

  void _subscribeToMessages() {
    client
        .channel('public:chatmessage')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chatmessage',
      callback: (payload) {
        final newMsg = payload.newRecord;
        if (newMsg != null) {
          _messages.add(newMsg);
          _messageStreamController.add(List.from(_messages));
        }
      },
    )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    await client.from('chatmessage').insert({
      'content': content,
      'user_id': userId,
    });

    _controller.clear();
  }

  Future<void> _signOut() async {
    await client.auth.signOut();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStreamController.stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final msg = messages[index];
                    final isMe = msg['user_id'] == userId;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['content'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['created_at']?.toString() ?? '',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade300),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type message...',
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
