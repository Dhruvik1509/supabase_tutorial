import 'package:flutter/material.dart';
import 'package:supabase_tutorial/supabase_Authatication/Loginscreem.dart';
import 'package:supabase_tutorial/supabase_Authatication/main.dart';
import 'package:supabase_tutorial/supabase_Authatication/widget.dart';

class Signupscreem extends StatefulWidget {
  const Signupscreem({super.key});

  @override
  State<Signupscreem> createState() => _SignupscreemState();
}

class _SignupscreemState extends State<Signupscreem> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool isLoadin = false;

  AuthaServies servies = AuthaServies();

  void _signUp() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (!email.contains(".com")) {
      showSackBar(context, "Invalid email. it must contain .com");
    }
    setState(() {
      isLoadin = true;
    });
    final result = await servies.signUp(email, password);
    if (result == null) {
      setState(() {
        isLoadin = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Loginscreem()),
      );
      showSackBar(context, "Signup Successful! Now turn to login");
    } else {
      setState(() {
        isLoadin = false;
      });
      showSackBar(context, "Signup Failed:$result");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              isLoadin
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _signUp,
                    child: Text('Signup', style: TextStyle(fontSize: 20)),
                  ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Loginscreem()),
                  );
                },
                child: Text('LOGIN', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
