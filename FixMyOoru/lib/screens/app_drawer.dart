// lib/screens/app_drawer.dart
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'user_profile.dart';
import 'login_register_screen.dart';

// lib/screens/app_drawer.dart

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // This builder now listens to our session service for instant UI updates
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: UserSessionService().currentUser,
      builder: (context, userData, child) {
        final bool isLoggedIn = userData != null;

        return Drawer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.map_outlined, size: 40, color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(height: 8),
                          Text('Bengaluru Civic Watch', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                          if (isLoggedIn) ...[
                            const SizedBox(height: 4),
                            Text(userData['name'] ?? 'User', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                            Text(userData['email'] ?? '', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                          ]
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text('Profile', style: theme.textTheme.bodyLarge),
                      onTap: () {
                        Navigator.pop(context);
                        if (isLoggedIn) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfile()));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()));
                        }
                      },
                    ),
                    if (isLoggedIn)
                      ListTile(
                        leading: const Icon(Icons.history_outlined),
                        title: Text('My Reports', style: theme.textTheme.bodyLarge),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('My Reports feature is coming soon!')));
                        },
                      ),
                    const Divider(),
                    if (!isLoggedIn)
                      ListTile(
                        leading: Icon(Icons.login, color: theme.colorScheme.primary),
                        title: Text('Login / Register', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()));
                        },
                      ),
                    if (isLoggedIn)
                      ListTile(
                        leading: Icon(Icons.logout, color: theme.colorScheme.error),
                        title: Text('Logout', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)),
                        onTap: () async {
                          await UserSessionService().clearUser();
                          await FirebaseAuth.instance.signOut();
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text('Version: ${snapshot.data!.version} (${snapshot.data!.buildNumber})', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}