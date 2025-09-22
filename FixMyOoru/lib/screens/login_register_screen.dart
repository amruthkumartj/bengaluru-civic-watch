// lib/screens/login_register_screen.dart
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class LoginOrRegisterScreen extends StatelessWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Bengaluru Civic Watch',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // Navigate to AuthScreen in LOGIN mode
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AuthScreen(isLogin: true),
                  ));
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Navigate to AuthScreen in REGISTER mode
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AuthScreen(isLogin: false),
                  ));
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}