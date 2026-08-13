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
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Stream<GoogleSignInAccount?> get onCurrentUserChanged => 
      _googleSignIn.authenticationEvents.map((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          return event.user;
        }
        return null;
      });

  static Future<void> initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        clientId: '398103262634-li80reb9n0rudq5s30bm5ctomucf2t1m.apps.googleusercontent.com',
      );
      if (kIsWeb) {
        await _googleSignIn.attemptLightweightAuthentication();
      }
    } catch (_) {}
  }


  /// Native Google Sign-In trigger
  static Future<UserProfile?> signInWithGoogle() async {
    try {
      debugPrint('[AuthService] Initiating Google Sign-In...');
      // Ensure initialized before authenticating just in case
      await _googleSignIn.initialize(
        clientId: '398103262634-li80reb9n0rudq5s30bm5ctomucf2t1m.apps.googleusercontent.com',
      );
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

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
