# Authentication API

Login, token management, and session handling.

## AuthService

```dart
class AuthService {
  final Dio dio;
  final FlutterSecureStorage storage;

  static const tokenKey = 'auth_token';
  static const refreshTokenKey = 'refresh_token';
  static const userKey = 'auth_user';

  AuthService({required this.dio, required this.storage});

  // Login with email/password
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final token = response.data?['token'] as String?;
    final refreshToken = response.data?['refresh_token'] as String?;
    final userData = response.data?['user'] as Map<String, dynamic>?;

    if (token == null || userData == null) {
      throw UnauthorizedException('Login failed');
    }

    final user = User.fromJson(userData);

    // Store tokens securely
    await storage.write(key: tokenKey, value: token);
    if (refreshToken != null) {
      await storage.write(key: refreshTokenKey, value: refreshToken);
    }
    await storage.write(key: userKey, value: jsonEncode(userData));

    return user;
  }

  // Refresh access token
  Future<void> refreshToken() async {
    final refreshToken = await storage.read(key: refreshTokenKey);
    if (refreshToken == null) throw UnauthorizedException('No refresh token');

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newToken = response.data?['token'] as String?;
      if (newToken == null) throw UnauthorizedException('Token refresh failed');

      await storage.write(key: tokenKey, value: newToken);
    } on DioException {
      // Refresh failed, clear auth state
      await logout();
      rethrow;
    }
  }

  // Get current token
  Future<String?> getToken() async {
    return await storage.read(key: tokenKey);
  }

  // Get stored user
  Future<User?> getStoredUser() async {
    final userJson = await storage.read(key: userKey);
    if (userJson == null) return null;

    try {
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    // Call logout endpoint (optional)
    try {
      await dio.post('/auth/logout');
    } catch (e) {
      // Ignore errors, clear locally regardless
    }

    // Clear stored auth state
    await Future.wait([
      storage.delete(key: tokenKey),
      storage.delete(key: refreshTokenKey),
      storage.delete(key: userKey),
    ]);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
```

## AuthNotifier (State Management)

```dart
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null && token != null;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;

  AuthNotifier(this.authService) : super(const AuthState());

  // Restore session on app start
  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true);

    try {
      final user = await authService.getStoredUser();
      final token = await authService.getToken();

      if (user != null && token != null) {
        state = state.copyWith(
          user: user,
          token: token,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await authService.login(email: email, password: password);
      final token = await authService.getToken();

      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
        error: null,
      );
    } on UnauthorizedException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid email or password',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await authService.logout();
    state = const AuthState();
  }

  // Refresh token (called by interceptor)
  Future<void> refreshToken() async {
    try {
      await authService.refreshToken();
      final token = await authService.getToken();
      state = state.copyWith(token: token);
    } catch (e) {
      // Token refresh failed, logout
      await logout();
    }
  }
}

// Riverpod provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  final notifier = AuthNotifier(authService);

  // Restore session on app start
  Future.microtask(() => notifier.restoreSession());

  return notifier;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    dio: ref.read(dioProvider),
    storage: const FlutterSecureStorage(),
  );
});
```

## Login Screen

```dart
class LoginScreen extends ConsumerWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (authState.error != null)
              Text(
                authState.error!,
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: authState.isLoading
                  ? null
                  : () => authNotifier.login(
                    email: _emailController.text,
                    password: _passwordController.text,
                  ),
              child: authState.isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  )
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## OAuth Integration

```dart
class OAuthAuthService extends AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Sign in cancelled');

      final googleAuth = await googleUser.authentication;

      final response = await dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: {
          'id_token': googleAuth.idToken,
          'access_token': googleAuth.accessToken,
        },
      );

      final token = response.data?['token'] as String?;
      final userData = response.data?['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw UnauthorizedException('OAuth sign in failed');
      }

      final user = User.fromJson(userData);
      await storage.write(key: tokenKey, value: token);
      await storage.write(key: userKey, value: jsonEncode(userData));

      return user;
    } catch (e) {
      throw NetworkException('Sign in failed: $e');
    }
  }
}
```

## Session Restoration

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... other setup ...

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Restore session automatically
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      home: authState.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
```
