import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_sign_in_service.dart';

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});
