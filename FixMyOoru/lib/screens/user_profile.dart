// lib/screens/user_profile.dart
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: UserSessionService().currentUser,
        builder: (context, userData, child) {
          if (userData == null) {
            return const Center(child: Text('You are not logged in. Please restart the app.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildProfileTile(context, Icons.person_outline, 'Name', userData['name'] ?? 'N/A'),
                    const Divider(height: 1),
                    _buildProfileTile(context, Icons.email_outlined, 'Email', userData['email'] ?? 'N/A'),
                    const Divider(height: 1),
                    _buildProfileTile(context, Icons.phone_outlined, 'Phone', userData['phone'] ?? 'N/A'),
                    const Divider(height: 1),
                    _buildProfileTile(context, Icons.home_outlined, 'Address', userData['address'] ?? 'N/A'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodySmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}