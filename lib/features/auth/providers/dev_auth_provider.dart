import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/dev_auth_helper.dart';

final devAuthHelperProvider = Provider<DevAuthHelper>((ref) {
  const storage = FlutterSecureStorage();
  return DevAuthHelper(storage);
});
