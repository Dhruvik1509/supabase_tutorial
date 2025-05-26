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
