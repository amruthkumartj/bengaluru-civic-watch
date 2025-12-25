// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/user_session.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String email;

  const ProfileScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // **FIX 1: Define the missing _formKey**
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // **FIX 2: Call validate() on the form key**
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do not proceed.
    }
    setState(() { _isLoading = true; });

    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final phone = _phoneController.text.trim();
      final phoneQuery = await usersCollection.where('phone', isEqualTo: phone).get();

      if (phoneQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This phone number is already registered.')),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final userData = {
        'uid': widget.uid,
        'name': _nameController.text.trim(),
        'phone': phone,
        'address': _addressController.text.trim(),
        'email': widget.email,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await usersCollection.doc(widget.uid).set(userData);
      print("User profile saved successfully!");

      if (mounted) {
        // After saving, also set the data in the session service
        UserSessionService().setUser(userData);
        Navigator.of(context).pop(true); // Pop back to signal success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        // **FIX 3: Wrap your input fields in a Form widget**
        child: Form(
          key: _formKey, // Assign the key to the Form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome! Please provide a few more details to get started.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              // Use TextFormField instead of TextField for validation
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Please enter a valid phone number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save & Continue'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}