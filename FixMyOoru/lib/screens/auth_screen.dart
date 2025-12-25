// lib/screens/auth_screen.dart
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin; // New property to determine the mode

  const AuthScreen({super.key, required this.isLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String _correctOtp = '';

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email.')));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection.where('email', isEqualTo: email).get();
      final userExists = querySnapshot.docs.isNotEmpty;

      // **NEW LOGIN/REGISTER LOGIC**
      if (widget.isLogin && !userExists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No account found. Please register.')));
        setState(() { _isLoading = false; });
        return;
      }
      if (!widget.isLogin && userExists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email already registered. Please log in.')));
        setState(() { _isLoading = false; });
        return;
      }

      // If checks pass, send OTP
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendOtpEmail');
      final result = await callable.call<Map<String, dynamic>>({'email': email});
      _correctOtp = result.data['otp'];
      setState(() { _otpSent = true; _isLoading = false; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
      setState(() { _isLoading = false; });
    }
  }

  // In _AuthScreenState class in auth_screen.dart

// In _AuthScreenState class in auth_screen.dart

  Future<void> _verifyOtpAndSignIn() async {
    if (_otpController.text.trim() != _correctOtp) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect OTP.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success!'), backgroundColor: Colors.green));
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      // This creates a persistent anonymous user session.
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;

      if (user != null && mounted) {
        if (widget.isLogin) {
          final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
          if (query.docs.isNotEmpty) {
            await UserSessionService().setUser(query.docs.first.data());
          }
          // Redirect to main dashboard (MapScreen)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MapScreen()),
            (route) => false,
          );
        } else { // Register
          final bool? success = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (context) => ProfileScreen(uid: user.uid, email: email)),
          );
          if (success == true && mounted) {
            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            if (doc.exists && doc.data() != null) {
              await UserSessionService().setUser(doc.data()!);
            }
            // Redirect to main dashboard (MapScreen)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MapScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign in: $e')));
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI text changes based on whether it's login or register mode
    final title = widget.isLogin ? 'Login' : 'Register';
    final buttonText = _otpSent ? 'Verify & Proceed' : 'Send OTP';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              !_otpSent ? 'Please enter your email to receive a code.' : 'An OTP has been sent. Please enter it below.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
            ],
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _otpSent ? _verifyOtpAndSignIn : _sendOtp,
                child: Text(buttonText),
              ),
          ],
        ),
      ),
    );
  }
}