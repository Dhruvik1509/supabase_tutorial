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
  late final String userId;

  List<Map<String, dynamic>> _messages = [];
  final StreamController<List<Map<String, dynamic>>> _messageStreamController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    final user = client.auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(); // Redirect to login
      });
    } else {
      userId = user.id;
      _loadMessages();
      _subscribeToRealtime();
    }
  }

  Future<void> _loadMessages() async {
    try {
      final response = await client
          .from('chatmessage')
          .select()
          .order('created_at', ascending: true);

      _messages = List<Map<String, dynamic>>.from(response);
      _messageStreamController.add(_messages);
    } catch (e) {
      debugPrint("Failed to load messages: $e");
    }
  }

  void _subscribeToRealtime() {
    _realtimeChannel = client
        .channel('public:chatmessage')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chatmessage',
      callback: (payload) {
        final newMsg = payload.newRecord;
        if (newMsg != null) {
          // Avoid duplicates (optional)
          final alreadyExists = _messages.any((m) =>
          m['content'] == newMsg['content'] &&
              m['user_id'] == newMsg['user_id'] &&
              m['created_at'] == newMsg['created_at']);
          if (!alreadyExists) {
            setState(() {
              _messages.add(newMsg);
              _messageStreamController.add(List.from(_messages));
            });
          }
        }
      },
    )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now().toIso8601String();

    // Add message to UI immediately (optimistic update)
    final localMessage = {
      'content': text,
      'user_id': userId,
      'created_at': now,
    };

    setState(() {
      _messages.add(localMessage);
      _messageStreamController.add(List.from(_messages));
    });

    _controller.clear();

    try {
      await client.from('chatmessage').insert({
        'content': text,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint("Failed to send message: $e");
    }
  }

  Future<void> _signOut() async {
    await client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageStreamController.close();
    if (_realtimeChannel != null) {
      client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['user_id'] == userId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey.shade700,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['content'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              softWrap: true,
            ),
            const SizedBox(height: 4),
            Text(
              msg['created_at']?.toString().substring(0, 19) ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messageStreamController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;
        return ListView.builder(
          reverse: false,
          padding: const EdgeInsets.only(top: 10, bottom: 70),
          itemCount: messages.length,
          itemBuilder: (_, index) => _buildMessage(messages[index]),
        );
      },
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      color: Colors.black12,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputField(),
        ],
      ),
    );
  }
}


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class WhatsappChatPage extends StatefulWidget {
//   const WhatsappChatPage({super.key});
//
//   @override
//   State<WhatsappChatPage> createState() => _WhatsappChatPageState();
// }
//
// class _WhatsappChatPageState extends State<WhatsappChatPage> {
//   final SupabaseClient client = Supabase.instance.client;
//   final TextEditingController _controller = TextEditingController();
//   late final String userId;
//
//   final ScrollController _scrollController = ScrollController();
//
//   List<Map<String, dynamic>> _messages = [];
//   final StreamController<List<Map<String, dynamic>>> _messageStreamController =
//   StreamController<List<Map<String, dynamic>>>.broadcast();
//
//   RealtimeChannel? _realtimeChannel;
//
//   @override
//   void initState() {
//     super.initState();
//     final user = client.auth.currentUser;
//
//     if (user == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         Navigator.of(context).pop();
//       });
//     } else {
//       userId = user.id;
//       _loadMessages();
//       _subscribeToRealtime();
//     }
//   }
//
//   Future<void> _loadMessages() async {
//     try {
//       final response = await client
//           .from('chatmessage')
//           .select()
//           .order('created_at', ascending: true);
//
//       _messages = List<Map<String, dynamic>>.from(response);
//       _messageStreamController.add(_messages);
//       _scrollToBottom();
//     } catch (e) {
//       debugPrint("Failed to load messages: $e");
//     }
//   }
//
//   void _subscribeToRealtime() {
//     _realtimeChannel = client
//         .channel('public:chatmessage')
//         .onPostgresChanges(
//       event: PostgresChangeEvent.insert,
//       schema: 'public',
//       table: 'chatmessage',
//       callback: (payload) {
//         final newMsg = payload.newRecord;
//         if (newMsg != null) {
//           final alreadyExists = _messages.any((m) =>
//           m['content'] == newMsg['content'] &&
//               m['user_id'] == newMsg['user_id'] &&
//               m['created_at'] == newMsg['created_at']);
//           if (!alreadyExists) {
//             setState(() {
//               _messages.add(newMsg);
//               _messageStreamController.add(List.from(_messages));
//             });
//             _scrollToBottom();
//           }
//         }
//       },
//     )
//         .subscribe();
//   }
//
//   Future<void> _sendMessage() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;
//
//     final now = DateTime.now().toIso8601String();
//
//     // Optimistic UI update
//     final localMessage = {
//       'content': text,
//       'user_id': userId,
//       'created_at': now,
//     };
//
//     setState(() {
//       _messages.add(localMessage);
//       _messageStreamController.add(List.from(_messages));
//     });
//
//     _controller.clear();
//     _scrollToBottom();
//
//     try {
//       await client.from('chatmessage').insert({
//         'content': text,
//         'user_id': userId,
//       });
//     } catch (e) {
//       debugPrint("Failed to send message: $e");
//     }
//   }
//
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent + 50,
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   Future<void> _signOut() async {
//     await client.auth.signOut();
//     if (mounted) {
//       Navigator.of(context).pop();
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _messageStreamController.close();
//     _scrollController.dispose();
//     if (_realtimeChannel != null) {
//       client.removeChannel(_realtimeChannel!);
//     }
//     super.dispose();
//   }
//
//   Widget _buildMessage(Map<String, dynamic> msg) {
//     final isMe = msg['user_id'] == userId;
//     final messageText = msg['content'] ?? '';
//     final timestampStr = msg['created_at']?.toString() ?? '';
//
//     // Format timestamp to HH:mm (you can customize)
//     String formattedTime = '';
//     try {
//       final dt = DateTime.parse(timestampStr);
//       formattedTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
//     } catch (_) {}
//
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         constraints: const BoxConstraints(maxWidth: 280),
//         decoration: BoxDecoration(
//           color: isMe ? const Color(0xffDCF8C6) : Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(18),
//             topRight: const Radius.circular(18),
//             bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
//             bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 1,
//               offset: const Offset(1, 1),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               messageText,
//               style: const TextStyle(fontSize: 16, color: Colors.black87),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               formattedTime,
//               style: TextStyle(fontSize: 11, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessageList() {
//     return StreamBuilder<List<Map<String, dynamic>>>(
//       stream: _messageStreamController.stream,
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         final messages = snapshot.data!;
//         return ListView.builder(
//           controller: _scrollController,
//           padding: const EdgeInsets.only(top: 10, bottom: 10),
//           itemCount: messages.length,
//           itemBuilder: (_, index) => _buildMessage(messages[index]),
//         );
//       },
//     );
//   }
//
//   Widget _buildInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             offset: const Offset(0, -1),
//             blurRadius: 4,
//           )
//         ],
//       ),
//       child: SafeArea(
//         child: Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: _controller,
//                 maxLines: null,
//                 textCapitalization: TextCapitalization.sentences,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message',
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 ),
//               ),
//             ),
//             IconButton(
//               icon: const Icon(Icons.send, color: Color(0xff075E54)),
//               onPressed: _sendMessage,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffECE5DD),
//       appBar: AppBar(
//         backgroundColor: const Color(0xff075E54),
//         title: const Text('WhatsApp Chat'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _signOut,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(child: _buildMessageList()),
//           _buildInputField(),
//         ],
//       ),
//     );
//   }
// }
