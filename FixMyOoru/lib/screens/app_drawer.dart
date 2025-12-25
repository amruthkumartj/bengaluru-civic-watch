import 'package:fixmyooru/services/theme_service.dart';
import 'package:fixmyooru/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'user_profile.dart';
import 'login_register_screen.dart';
import 'settings_screen.dart'; // Import the new settings screen
import 'package:fixmyooru/screens/my_reports_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: UserSessionService().currentUser,
        builder: (context, userData, child) {
          final bool isLoggedIn = userData != null;

          return Column( // The root is now a Column
            children: [
              // This Expanded makes the ListView take up all available space
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReportsScreen()));
                        },
                      ),
                    const Divider(),
                    // New 'Settings' ListTile
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: Text('Settings', style: theme.textTheme.bodyLarge),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      },
                    ),
                    // Login/Register button for logged out users
                    if (!isLoggedIn)
                      ListTile(
                        leading: Icon(Icons.login, color: theme.colorScheme.primary),
                        title: Text('Login / Register', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()));
                        },
                      ),
                    // The old Logout button is removed from here
                  ],
                ),
              ),
              // The Map Type selector is now pinned to the bottom
              _buildMapTypeSelector(context),
              const Divider(height: 1),
              // The version info
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
          );
        },
      ),
    );
  }

  // New method to build just the map type selector
  Widget _buildMapTypeSelector(BuildContext context) {
    return ValueListenableBuilder<MapDisplayType>(
      valueListenable: ThemeService().mapTypeNotifier,
      builder: (context, mapType, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Map Type', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildThemeChip(
                    context,
                    icon: Icons.map_outlined,
                    label: 'Normal',
                    isSelected: mapType == MapDisplayType.normal,
                    onTap: () => ThemeService().setMapType(MapDisplayType.normal),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeChip(
                    context,
                    icon: Icons.satellite_alt_outlined,
                    label: 'Satellite',
                    isSelected: mapType == MapDisplayType.satellite,
                    onTap: () => ThemeService().setMapType(MapDisplayType.satellite),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget for the theme chips
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
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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