import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_tutorial/Chat/Loginscreem.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hgavdqjslkwlidvuqxrg.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnYXZkcWpzbGt3bGlkdnVxeHJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc4OTU1MDQsImV4cCI6MjA2MzQ3MTUwNH0.teS_6nvXRm7h1iPSPaIIqkfpGP4wRLx41swsqsGvmdQ',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Auth Demo',
      home: Loginscreem(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthaServies{


  final supabase = Supabase.instance.client;
  Future<String?> signUp(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        password: password,
        email: email,
      );
      if (response.user != null) {
        return null;
      }
      return "An unknown error occurred.";
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        password: password,
        email: email,
      );
      if (response.user != null) {
        return null;
      }
      return "Login failed. Please check credentials.";
    } on AuthException catch (e) {
      return e.message;
    }
  }


  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Loginscreem()),
      );
    }
  }
}



