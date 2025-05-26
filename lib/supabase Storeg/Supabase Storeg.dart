import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;


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
    return MaterialApp(
      title: 'Supabase Storage Demo',
      home: const StoragePage(),
    );
  }
}




class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  final SupabaseClient client = Supabase.instance.client;
  final String bucket = 'images'; // Must match the actual bucket name
  List<String> files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }
  Future<void> _loadFiles() async {
    try {
      final response = await client.storage.from(bucket).list(path: '', searchOptions: const SearchOptions(limit: 1000));
      final allFiles = <String>[];

      for (final item in response) {
        if (item.name != null && item.name.isNotEmpty) {
          allFiles.add(item.name);
        }
      }

      setState(() {
        files = allFiles;
      });
    } catch (e) {
      _showMessage('Failed to load files: $e');
    }
  }

  /*Future<void> _loadFiles() async {
    try {
      final response = await client.storage.from(bucket).list();
      setState(() {
        files = response.map((f) => f.name).toList();
      });
    } catch (e) {
      _showMessage('Failed to load files: $e');
    }
  }*/
 /// Aounly Image
  // Future<void> _uploadFile() async {
  //   final result = await FilePicker.platform.pickFiles();
  //   if (result != null) {
  //     final file = result.files.single;
  //     final filePath = file.path!;
  //     final fileName = path.basename(filePath);
  //
  //     try {
  //       final fileBytes = File(filePath).readAsBytesSync();
  //       final mimeType = lookupMimeType(fileName);
  //
  //       await client.storage.from(bucket).uploadBinary(
  //         fileName,
  //         fileBytes,
  //         fileOptions: FileOptions(contentType: mimeType),
  //       );
  //       _showMessage('Uploaded: $fileName');
  //       _loadFiles();
  //     } catch (e) {
  //       print('$e');
  //       _showMessage('Upload failed: $e');
  //     }
  //   }
  // }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg', 'mp4', 'mov', 'avi']);
    if (result != null) {
      final file = result.files.single;
      final filePath = file.path!;
      final fileName = path.basename(filePath);
      final mimeType = lookupMimeType(fileName);

      // Check if file is image or video
      String subfolder = 'others/';
      if (mimeType != null) {
        if (mimeType.startsWith('image/')) {
          subfolder = 'images/';
        } else if (mimeType.startsWith('video/')) {
          subfolder = 'videos/';
        }
      }

      final storagePath = '$subfolder$fileName'; // e.g., images/photo.jpg or videos/clip.mp4

      try {
        final fileBytes = File(filePath).readAsBytesSync();

        await client.storage.from(bucket).uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

        _showMessage('Uploaded: $storagePath');
        _loadFiles();
      } catch (e) {
        print('$e');
        _showMessage('Upload failed: $e');
      }
    }
  }

  Future<void> _downloadFile(String fileName) async {
    try {
      final url = client.storage.from(bucket).getPublicUrl(fileName);
      _showMessage('Download URL:\n$url');
      // You can use url_launcher to open this URL
    } catch (e) {
      _showMessage('Download failed: $e');
    }
  }

  Future<void> _deleteFile(String fileName) async {
    try {
      await client.storage.from(bucket).remove([fileName]);
      _showMessage('Deleted: $fileName');
      _loadFiles();
    } catch (e) {
      _showMessage('Delete failed: $e');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Storage')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _uploadFile,
            child: const Text('Upload File'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Stored Files:', style: TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  title: Text(file),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => _downloadFile(file),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteFile(file),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

