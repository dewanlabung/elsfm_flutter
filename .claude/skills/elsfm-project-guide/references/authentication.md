# Authentication Flows

Dev mode, OAuth, and biometric authentication.

## Dev Mode Auto-Login

For testing without credentials.

```dart
// Enable dev mode
await devAuthHelper.enableDevMode();

// App auto-logs in with encrypted credentials
// Credentials stored: EncryptedSharedPreferences (Android), Keychain (iOS)

// Disable
await devAuthHelper.disableDevMode();
```

## OAuth (Google Sign-In)

Social authentication.

```dart
class OAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    // Send to backend
    final response = await dio.post('/auth/google', data: {
      'id_token': googleAuth.idToken,
      'access_token': googleAuth.accessToken,
    });

    final token = response.data['token'];
    await storage.write(key: 'auth_token', value: token);

    return User.fromJson(response.data['user']);
  }
}
```

## Biometric (Fingerprint/Face)

Local device authentication.

```dart
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock ELSFM',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;  // Biometric unavailable, fallback to password
    }
  }
}
```

## Session Restoration

On app start.

```dart
class AuthNotifier extends StateNotifier<AuthState> {
  Future<void> restoreSession() async {
    final token = await storage.read(key: 'auth_token');
    final userJson = await storage.read(key: 'auth_user');

    if (token != null && userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      state = state.copyWith(
        user: user,
        token: token,
        isAuthenticated: true,
      );
    }
  }
}

// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );

  // Restore session after app starts
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(authNotifierProvider.notifier).restoreSession();
  });
}
```

## Token Refresh

Automatic refresh before expiry.

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired, refresh
      await refreshToken();
      // Retry request
      return handler.resolve(await _retry(err.requestOptions));
    }
    handler.next(err);
  }

  Future<void> refreshToken() async {
    final response = await dio.post('/auth/refresh', data: {
      'refresh_token': await storage.read(key: 'refresh_token'),
    });
    await storage.write(key: 'auth_token', value: response.data['token']);
  }
}
```

## Logout

Clear session.

```dart
Future<void> logout() async {
  await dio.post('/auth/logout');
  
  // Clear local storage
  await Future.wait([
    storage.delete(key: 'auth_token'),
    storage.delete(key: 'refresh_token'),
    storage.delete(key: 'auth_user'),
  ]);

  // Notify UI
  state = const AuthState();
}
```

## Security

- ✅ Credentials in secure storage (never in code)
- ✅ HTTPS only
- ✅ SSL pinning (optional)
- ✅ Tokens rotated regularly
- ✅ Biometric fallback
- ✅ Session timeout
- ❌ Don't hardcode credentials
- ❌ Don't log tokens
