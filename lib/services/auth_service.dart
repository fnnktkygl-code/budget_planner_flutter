import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final bool isGuest;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.isGuest = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isGuest': isGuest,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        displayName: json['displayName'] ?? '',
        photoUrl: json['photoUrl'] ?? '',
        isGuest: json['isGuest'] ?? false,
      );
}

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with a specific Gmail address entered by the user
  static Future<UserProfile> signInWithGmailAddress(String userEmail) async {
    final cleanEmail = userEmail.trim().isEmpty ? 'fnnktkygl@gmail.com' : userEmail.trim();
    final namePart = cleanEmail.split('@').first;
    final formattedName = namePart[0].toUpperCase() + namePart.substring(1);

    final profile = UserProfile(
      id: 'usr-gmail-${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: formattedName,
      photoUrl: 'https://lh3.googleusercontent.com/a/default-user',
      isGuest: false,
    );
    await saveUserProfile(profile);
    return profile;
  }

  /// Native Google Sign-In trigger
  static Future<UserProfile?> signInWithGoogle() async {
    try {
      debugPrint('[AuthService] Initiating Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final profile = UserProfile(
          id: googleUser.id,
          email: googleUser.email,
          displayName: googleUser.displayName ?? googleUser.email.split('@').first,
          photoUrl: googleUser.photoUrl ?? '',
          isGuest: false,
        );
        await saveUserProfile(profile);
        return profile;
      }
      return null;
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In Exception: $e');
      return null;
    }
  }

  /// Sign in as Guest
  static Future<UserProfile> signInAsGuest() async {
    final profile = UserProfile(
      id: 'usr-guest-12345',
      email: 'guest@aurabudget.app',
      displayName: 'Invité AuraBudget',
      photoUrl: '',
      isGuest: true,
    );
    await saveUserProfile(profile);
    return profile;
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', profile.id);
    await prefs.setString('user_email', profile.email);
    await prefs.setString('user_display_name', profile.displayName);
    await prefs.setString('user_photo_url', profile.photoUrl);
    await prefs.setBool('user_is_guest', profile.isGuest);
    await prefs.setBool('user_is_signed_in', true);
  }

  static Future<UserProfile?> getSavedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final isSignedIn = prefs.getBool('user_is_signed_in') ?? false;
    if (!isSignedIn) return null;

    final id = prefs.getString('user_id') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final displayName = prefs.getString('user_display_name') ?? '';
    final photoUrl = prefs.getString('user_photo_url') ?? '';
    final isGuest = prefs.getBool('user_is_guest') ?? false;

    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isGuest: isGuest,
    );
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_display_name');
    await prefs.remove('user_photo_url');
    await prefs.remove('user_is_guest');
    await prefs.setBool('user_is_signed_in', false);
  }
}
