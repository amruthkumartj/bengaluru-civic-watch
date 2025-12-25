import 'package:fixmyooru/services/theme_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = UserSessionService().currentUser.value != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('App Theme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ValueListenableBuilder<AppTheme>(
            valueListenable: ThemeService().appThemeNotifier,
            builder: (context, appTheme, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildThemeChip(
                    context,
                    icon: Icons.brightness_auto_outlined,
                    label: 'System',
                    isSelected: appTheme == AppTheme.system,
                    onTap: () => ThemeService().setAppTheme(AppTheme.system),
                  ),
                  _buildThemeChip(
                    context,
                    icon: Icons.light_mode_outlined,
                    label: 'Light',
                    isSelected: appTheme == AppTheme.light,
                    onTap: () => ThemeService().setAppTheme(AppTheme.light),
                  ),
                  _buildThemeChip(
                    context,
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark',
                    isSelected: appTheme == AppTheme.dark,
                    onTap: () => ThemeService().setAppTheme(AppTheme.dark),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 48),
          if (isLoggedIn)
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
              onPressed: () async {
                await UserSessionService().clearUser();
                await FirebaseAuth.instance.signOut();
                // Pop back to the main map screen after logout
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
      ),
    );
  }

  // This is the same helper widget from the AppDrawer, now moved here
  Widget _buildThemeChip(BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colorScheme.secondaryContainer : colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}