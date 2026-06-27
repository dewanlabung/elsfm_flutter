import '../../../data/models/user.dart';

enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthStateData {
  final AuthState state;
  final String? errorMessage;
  final User? user;

  AuthStateData({
    required this.state,
    this.errorMessage,
    this.user,
  });

  factory AuthStateData.unauthenticated() {
    return AuthStateData(state: AuthState.unauthenticated);
  }

  factory AuthStateData.authenticated(User user) {
    return AuthStateData(state: AuthState.authenticated, user: user);
  }

  factory AuthStateData.error(String message) {
    return AuthStateData(
      state: AuthState.error,
      errorMessage: message,
    );
  }

  AuthStateData copyWith({
    AuthState? state,
    String? errorMessage,
    User? user,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}
