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
    final savedProfile = await AuthService.getSavedUserProfile();
    state = AuthState(
      user: savedProfile,
      isLoading: false,
    );
  }

  Future<void> signInWithGmailAddress(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final profile = await AuthService.signInWithGmailAddress(email);
    state = AuthState(user: profile, isLoading: false);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final profile = await AuthService.signInWithGoogle();
    if (profile != null) {
      state = AuthState(user: profile, isLoading: false);
    } else {
      state = AuthState(user: null, isLoading: false);
    }
  }

  Future<void> signInAsGuest() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final profile = await AuthService.signInAsGuest();
    state = AuthState(user: profile, isLoading: false);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await AuthService.signOut();
    state = AuthState(user: null, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
