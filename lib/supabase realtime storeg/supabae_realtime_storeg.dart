import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xuomijdylikriadmmcfn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1b21pamR5bGlrcmlhZG1tY2ZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc4MjA4NTIsImV4cCI6MjA2MzM5Njg1Mn0.uoGmIj2SWl5bmZXsElYyShukIe9D80pkLQGi6FegVNU',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RealtimeMessagesPage(),
    );
  }
}

class RealtimeMessagesPage extends StatefulWidget {
  const RealtimeMessagesPage({super.key});
  @override
  State<RealtimeMessagesPage> createState() => _RealtimeMessagesPageState();
}

class _RealtimeMessagesPageState extends State<RealtimeMessagesPage> {
  final SupabaseClient client = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  void _setupRealtime() {
    client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) {
      setState(() {
        messages = data;
      });
    });
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    await client.from('messages').insert({
      'content': content,
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ListTile(
                  title: Text(msg['content'] ?? ''),
                  subtitle: Text(msg['created_at'] ?? ''),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}