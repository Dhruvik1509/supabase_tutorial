import 'package:flutter/material.dart';
import 'package:supabase_tutorial/supabase_Authatication/Signupscreem.dart';
import 'package:supabase_tutorial/supabase_Authatication/widget.dart';
import 'package:supabase_tutorial/supabase_Authatication/home_page.dart';

import 'main.dart';

class Loginscreem extends StatefulWidget {
  const Loginscreem({super.key});

  @override
  State<Loginscreem> createState() => _LoginscreemState();
}

class _LoginscreemState extends State<Loginscreem> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool isLoadin = false;

  AuthaServies servies = AuthaServies();

  void _login()async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if(!mounted) return;
    setState(() {
      isLoadin = true;
    });
    final result = await servies.signIn(email, password);
    if(result == null){
      setState(() {
        isLoadin = false;
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(),));
      showSackBar(context, "Signup Successful! Now turn to login");
    }else{
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
              isLoadin ? Center(
                child:  CircularProgressIndicator()
              ) :
              ElevatedButton(
                onPressed: _login,
                child: Text('Login', style: TextStyle(fontSize: 20)),
              ),
              TextButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Signupscreem(),));
              }, child: Text('Signup',style: TextStyle(fontSize: 18),))
            ],
          ),
        ),
      ),
    );
  }
}
