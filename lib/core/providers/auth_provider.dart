import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isSignedIn => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoading: true)) {
    init();
  }

  Future<void> init() async {
    await AuthService.initGoogleSignIn();
    final savedProfile = await AuthService.getSavedUserProfile();
    state = AuthState(
      user: savedProfile,
      isLoading: false,
    );

    
    // Listen to Google Sign-In changes (especially required for Web where native button handles the flow)
    AuthService.onCurrentUserChanged.listen((googleUser) async {
      if (googleUser != null) {
        final profile = UserProfile(
          id: googleUser.id,
          email: googleUser.email,
          displayName: googleUser.displayName ?? googleUser.email.split('@').first,
          photoUrl: googleUser.photoUrl ?? '',
          isGuest: false,
        );
        await AuthService.saveUserProfile(profile);
        state = AuthState(user: profile, isLoading: false);
      }
    });
  }


  Future<void> signInWithGoogle() async {
    // DO NOT set state to isLoading: true BEFORE calling signInWithGoogle()
    // It breaks the browser's synchronous popup gesture requirement on Flutter Web!
    final profile = await AuthService.signInWithGoogle();
    
    if (profile != null) {
      state = AuthState(user: profile, isLoading: false);
    } else {
      // Failed or cancelled
      state = AuthState(user: null, isLoading: false);
    }
  }


  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await AuthService.signOut();
    state = AuthState(user: null, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
