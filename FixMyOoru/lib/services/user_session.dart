// lib/services/user_session.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class UserSessionService {
  static final UserSessionService _instance = UserSessionService._internal();
  factory UserSessionService() => _instance;
  UserSessionService._internal();

  final ValueNotifier<Map<String, dynamic>?> currentUser = ValueNotifier(null);
  final ValueNotifier<LatLng?> locationToFocus = ValueNotifier(null);

  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        currentUser.value = query.docs.first.data();
      }
    }
  }

  Future<void> setUser(Map<String, dynamic> userData) async {
    currentUser.value = userData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', userData['email']);
  }

  Future<void> clearUser() async {
    currentUser.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
  }
}